"""Small read-only PE architecture/import reader; no compiler or execution."""
import struct
from pathlib import Path

SYSTEM_DLLS=set('''advapi32 avrt bcrypt cfgmgr32 comctl32 comdlg32 crypt32 d3d11 d3d12 dbghelp dnsapi dsound dwmapi dxgi gdi32 glu32 hid imm32 iphlpapi kernel32 mpr msvcrt ncrypt netapi32 normaliz ntdll ole32 oleaut32 opengl32 powrprof propsys rpcrt4 secur32 setupapi shell32 shlwapi user32 userenv ucrtbase version winhttp wininet winmm winspool wintrust ws2_32 wsock32 wtsapi32 xinput1_4 xinput9_1_0'''.split())

def read(path):
    data=Path(path).read_bytes()
    if data[:2]!=b'MZ':raise ValueError('Not a PE file: '+str(path))
    pe=struct.unpack_from('<I',data,60)[0]
    if data[pe:pe+4]!=b'PE\0\0':raise ValueError('Invalid PE signature')
    machine,sections=struct.unpack_from('<HH',data,pe+4)
    optional_size=struct.unpack_from('<H',data,pe+20)[0]
    optional=pe+24
    magic=struct.unpack_from('<H',data,optional)[0]
    directories=optional+(112 if magic==0x20b else 96)
    import_rva,import_size=struct.unpack_from('<II',data,directories+8)
    section_table=optional+optional_size
    mappings=[]
    for i in range(sections):
        virtual_size,virtual,raw_size,raw=struct.unpack_from('<IIII',data,section_table+i*40+8)
        mappings.append((virtual,max(virtual_size,raw_size),raw))
    def offset(rva):
        for virtual,size,raw in mappings:
            if virtual<=rva<virtual+size:return raw+rva-virtual
        raise ValueError('Unmapped PE address')
    imports=[]
    if import_rva:
        table=offset(import_rva)
        for i in range(min(import_size//20+1,4096)):
            row=struct.unpack_from('<IIIII',data,table+i*20)
            if not any(row):break
            start=offset(row[3]);end=data.index(b'\0',start)
            imports.append(data[start:end].decode('ascii'))
    return {'file':Path(path).name,'machine':hex(machine),'x64':machine==0x8664,'imports':imports}

def closure(directory):
    files=sorted(Path(directory).glob('*.dll'))
    present={p.name.lower() for p in files}
    rows=[]
    for file in files:
        row=read(file)
        row['missing_imports']=[name for name in row['imports'] if name.lower() not in present and not name.lower().startswith(('api-ms-win-','ext-ms-win-')) and name.lower().replace('.dll','') not in SYSTEM_DLLS]
        rows.append(row)
    return rows
