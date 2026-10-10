#ifndef ESAVESTORE_H
#define ESAVESTORE_H

// Native payload remains byte-compatible. A checked, versioned presentation
// trailer travels in the same atomic file; legacy SDL readers ignore the trailer.
#include <array>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <functional>
#include <sstream>
#include <string>
#include <vector>
#include <cstdint>
#include <cerrno>
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
// The SDK's legacy COM/segmented-memory keywords conflict with native names.
#ifdef interface
#undef interface
#endif
#ifdef near
#undef near
#endif
#ifdef far
#undef far
#endif
#include <io.h>
#include <process.h>
#else
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>
#endif

namespace eSaveStore {
namespace fs=std::filesystem;
constexpr std::array<char,16> begin{{'E','Z','3','D','S','A','V','E','-','B','E','G','I','N','0','1'}};
constexpr std::array<char,16> end{{'E','Z','3','D','S','A','V','E','-','E','N','D','0','0','0','1'}};
constexpr uint64_t maxBytes=512ull*1024*1024;
constexpr uint32_t maxMetadata=16*1024*1024;
constexpr size_t footerBytes=40;
struct Check { std::string error,metadata; uint64_t nativeBytes=0,bytes=0; bool guarded=false; };
struct Result { std::string error,temporary; uint64_t bytes=0; bool durability=true; };
inline uint64_t number(const char* p,size_t n) { uint64_t v=0;for(size_t i=0;i<n;++i)v|=uint64_t(static_cast<unsigned char>(p[i]))<<(i*8);return v; }
inline void put(std::ostream& f,uint64_t value,size_t n) { for(size_t i=0;i<n;++i)f.put(char(value>>(i*8))); }
inline uint32_t crc(std::istream& f,uint64_t count) {
    static const auto table=[] { std::array<uint32_t,256> t{};for(uint32_t i=0;i<256;++i){uint32_t c=i;for(int j=0;j<8;++j)c=(c>>1)^((c&1)?0xedb88320u:0u);t[i]=c;}return t; }();
    uint32_t result=0xffffffffu;std::array<char,16384> buffer{};
    while(count) { auto n=std::min<uint64_t>(count,buffer.size());f.read(buffer.data(),std::streamsize(n));if(uint64_t(f.gcount())!=n)return 0;for(size_t i=0;i<n;++i)result=table[(result^uint8_t(buffer[i]))&255]^(result>>8);count-=n; }
    return result^0xffffffffu;
}
inline Check inspect(const fs::path& path,int nativeVersion) {
    Check result;std::error_code ec;result.bytes=fs::file_size(path,ec);
    if(ec) { result.error="save_not_found";return result; }
    if(result.bytes<16 || result.bytes>maxBytes) { result.error="invalid_save";return result; }
    std::ifstream f(path,std::ios::binary);std::array<char,16> header{};f.read(header.data(),header.size());
    if(!f || number(header.data(),4)!=8 || std::string(header.data()+4,8)!="eZeus.ez") {result.error="invalid_save";return result;}
    const auto version=number(header.data()+12,4);
    if(version>uint64_t(nativeVersion)) {result.error="incompatible_save";return result;}
    result.nativeBytes=result.bytes;
    if(result.bytes<footerBytes)return result;
    std::array<char,footerBytes> tail{};f.seekg(std::streamoff(result.bytes-footerBytes));f.read(tail.data(),tail.size());
    if(!std::equal(end.begin(),end.end(),tail.begin()))return result;
    result.guarded=true;
    if(number(tail.data()+16,4)!=1) {result.error="incompatible_save";return result;}
    auto metadata=number(tail.data()+20,4);result.nativeBytes=number(tail.data()+24,8);
    if(metadata>maxMetadata || result.nativeBytes<16 || result.nativeBytes>result.bytes || result.nativeBytes+begin.size()+metadata+footerBytes!=result.bytes) {result.error="invalid_save";return result;}
    std::array<char,16> marker{};f.seekg(std::streamoff(result.nativeBytes));f.read(marker.data(),marker.size());
    if(marker!=begin) {result.error="invalid_save";return result;}
    result.metadata.resize(size_t(metadata));if(metadata)f.read(result.metadata.data(),std::streamsize(metadata));
    f.clear();f.seekg(0);const auto actual=crc(f,result.bytes-footerBytes);
    if(!f || actual!=number(tail.data()+32,4))result.error="save_checksum_failed";
    return result;
}
inline bool seal(const fs::path& path,const std::string& metadata) {
    std::error_code ec;const auto bytes=fs::file_size(path,ec);if(ec || bytes>maxBytes || metadata.size()>maxMetadata)return false;
    {std::ofstream f(path,std::ios::binary|std::ios::app);f.write(begin.data(),begin.size());f.write(metadata.data(),metadata.size());f.flush();if(!f)return false;}
    std::ifstream source(path,std::ios::binary);const auto checksum=crc(source,bytes+begin.size()+metadata.size());if(!source)return false;
    std::ofstream f(path,std::ios::binary|std::ios::app);f.write(end.data(),end.size());put(f,1,4);put(f,metadata.size(),4);put(f,bytes,8);put(f,checksum,4);put(f,0,4);f.flush();return bool(f);
}
inline int pid() {
#ifdef _WIN32
    return _getpid();
#else
    return int(getpid());
#endif
}
inline bool alive(int id) {
    if(id<=0)return true;
#ifdef _WIN32
    const auto handle=OpenProcess(SYNCHRONIZE,FALSE,DWORD(id));if(!handle)return GetLastError()==ERROR_ACCESS_DENIED;
    const bool live=WaitForSingleObject(handle,0)==WAIT_TIMEOUT;CloseHandle(handle);return live;
#else
    return kill(id,0)==0 || errno==EPERM;
#endif
}
inline bool syncFile(const fs::path& path) {
#ifdef _WIN32
    const auto handle=CreateFileW(path.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,nullptr);if(handle==INVALID_HANDLE_VALUE)return false;
    bool ok=FlushFileBuffers(handle);CloseHandle(handle);return ok;
#else
    const int fd=::open(path.c_str(),O_RDONLY);if(fd<0)return false;bool ok=::fsync(fd)==0;
#ifdef __APPLE__
    if(ok && fcntl(fd,F_FULLFSYNC)==-1 && errno!=EINVAL && errno!=ENOTSUP)ok=false;
#endif
    ::close(fd);return ok;
#endif
}
inline bool syncDirectory(const fs::path& path) {
#ifdef _WIN32
    (void)path;return true; // Replacement itself requests write-through below.
#else
    const int fd=::open(path.c_str(),O_RDONLY);if(fd<0)return false;bool ok=::fsync(fd)==0;::close(fd);return ok;
#endif
}
inline bool replace(const fs::path& from,const fs::path& to) {
#ifdef _WIN32
    return bool(MoveFileExW(from.c_str(),to.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH));
#else
    std::error_code ec;fs::rename(from,to,ec);return !ec;
#endif
}
struct Lock {
    fs::path path;bool owned=false;
    explicit Lock(const fs::path& target):path(target.string()+".lock") {
        std::error_code ec;owned=fs::create_directory(path,ec);
        if(!owned && !ec) {
            int owner=0;std::ifstream(path/"owner")>>owner;
            if(owner>0 && !alive(owner)) { fs::remove(path/"owner",ec);fs::remove(path,ec);ec.clear();owned=fs::create_directory(path,ec); }
        }
        if(owned) { std::ofstream f(path/"owner");f<<pid()<<'\n';f.flush();if(!f){fs::remove(path/"owner",ec);fs::remove(path,ec);owned=false;} }
    }
    ~Lock() {if(owned){std::error_code ec;fs::remove(path/"owner",ec);fs::remove(path,ec);}}
};
inline Result commit(const fs::path& target,int nativeVersion,const std::string& metadata,const std::function<bool(const fs::path&)>& writer,const std::string& fail="") {
    Result result;Lock lock(target);if(!lock.owned){result.error="save_in_progress";return result;}
    static std::atomic<uint64_t> next{0};const auto suffix=".tmp-"+std::to_string(pid())+"-"+std::to_string(++next);
    const fs::path temporary(target.string()+suffix);result.temporary=temporary.filename().string();std::error_code ec;
    if(!writer(temporary) || !seal(temporary,metadata) || !syncFile(temporary)) {fs::remove(temporary,ec);result.error="save_failed";return result;}
    result.bytes=fs::file_size(temporary,ec);
    if(ec || !inspect(temporary,nativeVersion).error.empty()) {fs::remove(temporary,ec);result.error="save_failed";return result;}
    // Validators simulate an interruption here. The complete pending copy is
    // retained for recovery; the original destination has not been changed.
    if(fail=="after_write") {result.error="save_failed";return result;}
    const fs::path backup1(target.string()+".bak1"),backup2(target.string()+".bak2");
    const auto copy=[&](const fs::path& from,const fs::path& to) {
        const fs::path stage(to.string()+suffix);std::error_code error;fs::copy_file(from,stage,fs::copy_options::none,error);
        if(error || !syncFile(stage) || !replace(stage,to)){fs::remove(stage,error);return false;}return syncDirectory(target.parent_path());
    };
    if(fs::exists(target,ec)) {
        const auto old=inspect(target,nativeVersion);
        if(old.error.empty() && old.guarded) {
            if(fs::exists(backup1,ec) && inspect(backup1,nativeVersion).error.empty() && !copy(backup1,backup2)) {result.error="save_backup_failed";return result;}
            if(fail=="before_backup" || !copy(target,backup1)) {result.error="save_backup_failed";return result;}
        } else if(old.error.empty()) {
            // A footerless legacy file has not had a full parser check here.
            // Preserve it without displacing either checked recovery generation.
            if(!copy(target,fs::path(target.string()+".bak0"))) {result.error="save_backup_failed";return result;}
        } else if(!copy(target,fs::path(target.string()+".damaged"))) {result.error="save_backup_failed";return result;}
    }
    if(fail=="before_replace" || !replace(temporary,target)) {result.error="save_failed";return result;}
    result.temporary.clear();result.durability=syncDirectory(target.parent_path());return result;
}
}
#endif
