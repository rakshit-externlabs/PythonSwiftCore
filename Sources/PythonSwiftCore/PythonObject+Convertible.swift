

import Foundation
#if BEEWARE
import PythonLib
#endif

public protocol PyConvertible {
    
    var pyObject: PythonObject { get }
    var pyPointer: PyPointer { get }
}


public protocol ConvertibleFromPython {

    init(_ object: PythonObject)
    init?(_ ptr: PyPointer)
    init(object: PyPointer) throws
}

public protocol ConvertibleFromPython_WithCheck {
    init?(withCheck p: PyPointer)
}


extension PythonObject : PyConvertible, ConvertibleFromPython {
    
    
//    public init(_ ptr: PyPointer) {
//        self.init(getter: ptr)
//    }
    
    public var pyPointer: PyPointer {
        ptr
    }
    
    public var pyObject: PythonObject {
        self
    }

    
    public init(_ object: PythonObject) {
        self = object
    }
    
    public init(object: PyPointer) throws {
        self = .init(getter: object)
    }
    
    public init?(_ ptr: PyPointer) {
        if ptr == PythonNone {
            return nil
        }
        self = .init(getter: ptr)
    }

}

extension PyPointer : PyConvertible, ConvertibleFromPython, ConvertibleFromPython_WithCheck {
    
    
    public var pyObject: PythonObject {
        .init(getter: self)
    }
    
    public var pyPointer: PyPointer {
        self
    }
    
    public init(_ object: PythonObject) {
        self = object.ptr
    }
    
    public init(object: PyPointer) throws {
        self = object
    }
    
    public init?(_ ptr: PyPointer) {
        if ptr == PythonNone {
            return nil
        }
        self = ptr
    }
    

    public init?(withCheck p: PyPointer) {
        if p == PythonNone {
            return nil
        }
        self = p
    }
    
    
}

extension UnsafeMutablePointer<_object> : PyConvertible, ConvertibleFromPython {
    public var pyObject: PythonObject {
        .init(getter: self)
    }
    
    public var pyPointer: PyPointer {
        self
    }
    
    public init(_ object: PythonObject) {
        if let ptr = object.ptr {
            self = ptr
        } else {
            self = PyPointer.PyNone!
        }
    }
    
    public init(_ ptr: PyPointer) {
        self = ptr!
    }
    
    public init(object: PyPointer) throws {
        guard let o = object else { throw PythonError.attribute }
        self = o
    }
    
}

extension Data? {
    public var pyPointer: PyPointer {
        self?.pyPointer
    }
}

extension Data: ConvertibleFromPython, PyConvertible {
    public var pyObject: PythonObject {
        .init(getter: nil)
    }
    
    public var pyPointer: PyPointer {
        var this = self
        return this.withUnsafeMutableBytes { buffer -> PyPointer in
            let size = self.count //* uint8_size
            var pybuf = Py_buffer()
            PyBuffer_FillInfo(&pybuf, nil, buffer.baseAddress, size , 0, PyBUF_WRITE)
            let mem = PyMemoryView_FromBuffer(&pybuf)
            let bytes = PyBytes_FromObject(mem)
            Py_DecRef(mem)
            return bytes
        }
    }
    
    public init?(_ ptr: PyPointer) {
        self.init()
    }
    
    public init(_ object: PythonObject) {
        self.init()
    }
    
    public init(object: PyPointer) throws {
        self = object.memoryViewAsData() ?? .init()
    }
}

extension Bool : PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        if self {
            return .True
        }
        return .False
    }
    
    public var pyObject: PythonObject {
        if self {
            return .init(getter: .True)
        }
        return .init(getter: .False)
    }
    
    public init(_ object: PythonObject) {
        if object.ptr == .True {
            self = true
        } else {
            self = false
        }
    }
    public init?(_ ptr: PyPointer) {
        if ptr == .True {
            self = true
        } else if ptr == .False {
            self = false
        } else {
            return nil
        }
    }
    
    public init(object: PyPointer) throws {
        if object == PythonTrue {
            self = true
        } else if object == PythonFalse {
            self = false
        } else {
            throw PythonError.attribute
            return
        }
        
    }
}

extension String? {
    public var pyPointer: PyPointer {
        if let this = self {
            return this.withCString(PyUnicode_FromString)
        }
        return .PyNone
    }
}

extension String : PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        withCString(PyUnicode_FromString)
    }
    
    public var pyObject: PythonObject {
        .init(getter: withCString(PyUnicode_FromString) )
    }
    
    public init(_ object: PythonObject) {
        if object.isNone {
            self = "None"
        } else {
            self.init(cString: PyUnicode_AsUTF8(object.ptr))
        }
        
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonUnicode_Check(ptr) else { return nil }
        self.init(cString: PyUnicode_AsUTF8(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonUnicode_Check(object) else { throw PythonError.unicode }
        self.init(cString: PyUnicode_AsUTF8(object))
    }
    
}


extension URL? {
    public var pyPointer: PyPointer {
        if let this = self {
            return this.pyPointer
        }
        return .PyNone
    }
}

extension URL : PyConvertible, ConvertibleFromPython {
    public var pyObject: PythonObject {
        .init(getter: path.withCString(PyUnicode_FromString))
    }
    
    public var pyPointer: PyPointer {
        path.withCString(PyUnicode_FromString)
    }
    
    public init(_ object: PythonObject) {
        self.init(string: .init(object))!
    }
    
    public init?(_ ptr: PyPointer) {
        guard let string = String(ptr) else { return nil }
        self.init(string: string)
    }
    
    public init(object: PyPointer) throws {
        guard PythonUnicode_Check(object) else { throw PythonError.unicode }
        let path = String(cString: PyUnicode_AsUTF8(object))
        guard let url = URL(string: path) else { throw URLError(.badURL) }
        self = url
    }
    
}

extension Int : PyConvertible, ConvertibleFromPython {
    
    public var pyPointer: PyPointer {
        PyLong_FromLong(self)
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLong(self))
    }
    
    public init(_ object: PythonObject) {
        self = PyLong_AsLong(object.ptr)
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self = PyLong_AsLong(ptr)
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self = PyLong_AsLong(object)
    }
}

extension UInt : PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromUnsignedLong(self)
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromUnsignedLong(self))
    }
    
    public init(_ object: PythonObject) {
        self = PyLong_AsUnsignedLong(object.ptr)
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self = PyLong_AsUnsignedLong(ptr)
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self = PyLong_AsUnsignedLong(object)
    }
}
extension Int64: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromLongLong(self)
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLongLong(self))
    }
    
    public init(_ object: PythonObject) {
        self = PyLong_AsLongLong(object.ptr)
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self = PyLong_AsLongLong(ptr)
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self = PyLong_AsLongLong(object)
    }
}

extension UInt64: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromUnsignedLongLong(self)
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromUnsignedLongLong(self))
    }
    
    public init(_ object: PythonObject) {
        self.init(PyLong_AsUnsignedLongLong(object.ptr))
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self = PyLong_AsUnsignedLongLong(ptr)
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self = PyLong_AsUnsignedLongLong(object)
    }
}

extension Int32: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromLong(Int(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLong(Int(self)))
    }
    
    public init(_ object: PythonObject) {
        self = _PyLong_AsInt(object.ptr)
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self = _PyLong_AsInt(ptr)
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self = _PyLong_AsInt(object)
    }
}

extension UInt32: PyConvertible, ConvertibleFromPython {
    
    public var pyPointer: PyPointer {
        PyLong_FromLong(Int(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLong(Int(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(PyLong_AsUnsignedLong(object.ptr))
    }
    
    public init?(_ ptr: PyPointer) {
        self.init(PyLong_AsUnsignedLong(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self.init(PyLong_AsUnsignedLong(object))
    }
}

extension Int16: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromLong(Int(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLong(Int(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(clamping: PyLong_AsLong(object.ptr))
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self.init(clamping: PyLong_AsLong(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self.init(clamping: PyLong_AsLong(object))
    }
    
}

extension UInt16: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromUnsignedLong(UInt(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromUnsignedLong(UInt(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(clamping: PyLong_AsUnsignedLong(object.ptr))
    }
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self.init(clamping: PyLong_AsUnsignedLong(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self.init(clamping: PyLong_AsUnsignedLong(object))
    }
    
}

extension Int8: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromLong(Int(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromLong(Int(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(clamping: PyLong_AsLong(object.ptr))
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self.init(clamping: PyLong_AsLong(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self.init(clamping: PyLong_AsUnsignedLong(object))
    }
    
}

extension UInt8: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyLong_FromUnsignedLong(UInt(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyLong_FromUnsignedLong(UInt(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(clamping: PyLong_AsUnsignedLong(object.ptr))
    }
    public init?(_ ptr: PyPointer) {
        guard PythonLong_Check(ptr) else { return nil }
        self.init(clamping: PyLong_AsUnsignedLong(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonLong_Check(object) else { throw PythonError.long }
        self.init(clamping: PyLong_AsUnsignedLong(object))
    }
}

extension Double: PyConvertible, ConvertibleFromPython {
    
    
    public var pyPointer: PyPointer {
        PyFloat_FromDouble(self)
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyFloat_FromDouble(self))
    }
    
    public init(_ object: PythonObject) {
        self = PyFloat_AsDouble(object.ptr)
    }
    
    public init?(_ ptr: PyPointer) {
        self = PyFloat_AsDouble(ptr)
    }
    
    init?(p: PyPointer) {
        if PythonFloat_Check(p) {
            self = PyFloat_AsDouble(p)
        } else {
            return nil
        }
    }
    public init(object: PyPointer) throws {
        if PythonFloat_Check(object){
            self = PyFloat_AsDouble(object)
        } else if PythonLong_Check(object) {
            self = PyLong_AsDouble(object)
        }
        else { throw PythonError.float }
        
    }
}

extension Float32: PyConvertible, ConvertibleFromPython {
    
    public var pyPointer: PyPointer {
        PyFloat_FromDouble(Double(self))
    }
    
    public var pyObject: PythonObject {
        .init(getter: PyFloat_FromDouble(Double(self)))
    }
    
    public init(_ object: PythonObject) {
        self.init(PyFloat_AsDouble(object.ptr))
    }
    
    public init?(_ ptr: PyPointer) {
        guard PythonFloat_Check(ptr) else { return nil }
        self.init(PyFloat_AsDouble(ptr))
    }
    
    public init(object: PyPointer) throws {
        guard PythonFloat_Check(object) else { throw PythonError.float }
        self.init(PyFloat_AsDouble(object))
    }
}




extension Array : PyConvertible, ConvertibleFromPython where Element : PyConvertible & ConvertibleFromPython {
    public init?(_ ptr: PyPointer) {
        if PythonList_Check(ptr) {
            self = ptr.getBuffer().compactMap(Element.init)
        } else if PythonTuple_Check(ptr) {
            self = ptr.getBuffer().compactMap(Element.init)
        } else {
            return nil
        }
    }
    
    public init(object: PyPointer) throws {
        if PythonList_Check(object) {
            self = try object.getBuffer().map(Element.init)
        } else if PythonTuple_Check(object) {
            self = try object.getBuffer().map(Element.init)
        } else {
            throw PythonError.sequence
        }
    }
    
    public init(_ object: PythonObject) {
        let ptr = object.ptr
        if PythonList_Check(ptr) {
            self = ptr.getBuffer().compactMap(Element.init)
        } else if PythonTuple_Check(ptr) {
            self = ptr.getBuffer().compactMap(Element.init)
        } else {
            self.init()
        }
    }
    
    public var pyPointer: PyPointer {
        let list = PyList_New(count)
        for (index, element) in enumerated() {
            // `PyList_SetItem` steals the reference of the object stored.
            let obj = element.pyPointer
            PyList_SetItem(list, index, obj)
            Py_DecRef(obj)
        }
        return list
    }
    
    public var pyObject: PythonObject {
        let list = PyList_New(count)
        for (index, element) in enumerated() {
            // `PyList_SetItem` steals the reference of the object stored.
            let obj = element.pyPointer
            PyList_SetItem(list, index, element.pyPointer)
            Py_DecRef(obj)
        }
        return .init(getter: list)
    }

}

extension Dictionary<String,PyConvertible>: PyConvertible  {

    
    public var pyObject: PythonObject {
        .init(getter: pyPointer)
    }
    
    public var pyPointer: PyPointer {
        let dict = PyDict_New()
        for (key,value) in self {
            let v = value.pyPointer
            _ = key.withCString{PyDict_SetItemString(dict, $0, v)}
            Py_DecRef(v)
        }
        return dict
    }
    
    
}



extension Error {
    public var pyPointer: PyPointer {
        localizedDescription.pyPointer
    }
}
extension Optional where Wrapped == Error {
    public var pyPointer: PyPointer {
        if let this = self {
            return this.localizedDescription.pyPointer
        }
        return .PyNone
    }
}
