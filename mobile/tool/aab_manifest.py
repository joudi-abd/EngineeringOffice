#!/usr/bin/env python3
"""Prints the package, versionCode and versionName stored in an .aab's base manifest.

aapt2 cannot read .aab files (their manifest is protobuf-encoded), and bundletool is not installed, so this
reads the few fields it needs straight from the protobuf wire format (aapt2 Resources.proto: XmlNode,
XmlElement, XmlAttribute). Read-only; standard library only.

    python3 tool/aab_manifest.py dist/UFUQ-1.0.8.aab
    package=com.ufuq.imperium
    versionCode=12
    versionName=1.0.8
"""
import sys
import zipfile


def varint(buf, i):
    shift = result = 0
    while True:
        b = buf[i]
        i += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, i
        shift += 7


def fields(buf):
    """Yields (field number, wire type, value) for one protobuf message."""
    i = 0
    while i < len(buf):
        key, i = varint(buf, i)
        number, wire = key >> 3, key & 7
        if wire == 0:
            value, i = varint(buf, i)
        elif wire == 2:
            size, i = varint(buf, i)
            value, i = buf[i : i + size], i + size
        elif wire == 1:
            value, i = buf[i : i + 8], i + 8
        elif wire == 5:
            value, i = buf[i : i + 4], i + 4
        else:
            raise ValueError("unsupported protobuf wire type %d" % wire)
        yield number, wire, value


def attributes(element):
    for number, wire, value in fields(element):
        if number == 4 and wire == 2:  # XmlElement.attribute
            attr = {}
            for n, w, v in fields(value):
                if n == 1:
                    attr["ns"] = v.decode()
                elif n == 2:
                    attr["name"] = v.decode()
                elif n == 3:
                    attr["value"] = v.decode()
            yield attr


def main():
    if len(sys.argv) != 2:
        print("usage: aab_manifest.py <file.aab>", file=sys.stderr)
        return 1
    with zipfile.ZipFile(sys.argv[1]) as z:
        manifest = z.read("base/manifest/AndroidManifest.xml")
    element = next(v for n, w, v in fields(manifest) if n == 1)  # XmlNode.element
    found = {}
    for attr in attributes(element):
        found[attr.get("name")] = attr.get("value", "")
    print("package=%s" % found.get("package", ""))
    print("versionCode=%s" % found.get("versionCode", ""))
    print("versionName=%s" % found.get("versionName", ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
