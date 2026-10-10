#!/usr/bin/env python3
"""Real filesystem fault/recovery checks over synthetic payloads in a private folder."""
from pathlib import Path
import subprocess
import tempfile

REPO=Path(__file__).resolve().parents[1]
SOURCE=r'''
#include "presentation/esavestore.h"
#include <iostream>
#include <stdexcept>
using namespace eSaveStore;
int tests=0;
void check(bool value,const char* name){++tests;std::cout<<"SAVE_STORE "<<(value?"PASS ":"FAIL ")<<name<<'\n';if(!value)throw std::runtime_error(name);}
std::string bytes(const fs::path& p){std::ifstream f(p,std::ios::binary);return {std::istreambuf_iterator<char>(f),{}};}
bool write(const fs::path& p,char value){std::ofstream f(p,std::ios::binary);put(f,8,4);f<<"eZeus.ez";put(f,6,4);f<<std::string(2048,value);return bool(f);}
int main(int argc,char** argv){
    fs::path folder(argv[1]),target=folder/"city.ez";
    auto save=[&](char v,const std::string& fail=""){return commit(target,6,"PRESENTATION 1\nSPEED 0\nCAMERA 0 -1\nFACING 0\n",[&](const auto& p){return write(p,v);},fail);};
    check(save('a').error.empty(),"first save completes and syncs");
    auto first=bytes(target);check(inspect(target,6).guarded && inspect(target,6).error.empty(),"guarded file verifies");
    check(save('b').error.empty() && bytes(target.string()+".bak1")==first,"overwrite preserves exact previous copy");
    auto second=bytes(target);check(save('c').error.empty() && bytes(target.string()+".bak2")==first && bytes(target.string()+".bak1")==second,"two previous generations survive overwrite");
    auto third=bytes(target);
    for(auto point:{"after_write","before_backup","before_replace"}){
        auto failed=save('d',point);check(!failed.error.empty() && bytes(target)==third,"injected interruption leaves committed primary unchanged");
        check(!failed.temporary.empty() && inspect(folder/failed.temporary,6).error.empty(),"interrupted complete staging file is recoverable");
    }
    {Lock lock(target);check(lock.owned && save('e').error=="save_in_progress" && bytes(target)==third,"concurrent writer is refused without changing a save");}
    auto bad=third;bad[100]^=1;{std::ofstream f(target,std::ios::binary);f<<bad;}
    check(inspect(target,6).error=="save_checksum_failed","one changed payload byte fails integrity");
    auto backup=bytes(target.string()+".bak1");check(save('e').error.empty() && bytes(target.string()+".bak1")==backup && bytes(target.string()+".damaged")==bad,"corrupt primary is preserved and cannot replace the good backup");
    fs::path legacy=folder/"legacy.ez";write(legacy,'l');check(inspect(legacy,6).error.empty() && !inspect(legacy,6).guarded,"legacy native payload remains supported");
    auto newer=bytes(legacy);newer[12]=7;{std::ofstream f(legacy,std::ios::binary);f<<newer;}
    check(inspect(legacy,6).error=="incompatible_save","newer native version is refused");
    for(size_t n:{0,3,15}){std::ofstream f(legacy,std::ios::binary);f<<std::string(n,'x');f.close();check(!inspect(legacy,6).error.empty(),"truncated header is refused");}
    check(!fs::exists(target.string()+".lock"),"writer locks release on all return paths");
    std::cout<<"SAVE_STORE_VALIDATION PASS checks="<<tests<<'\n';
}
'''

def main():
    with tempfile.TemporaryDirectory(prefix='ezeus-save-store-') as folder:
        root=Path(folder);source=root/'check.cpp';source.write_text(SOURCE)
        executable=root/'check'
        subprocess.run(['/usr/bin/c++','-std=c++17','-O1','-I',str(REPO),str(source),'-o',str(executable)],check=True)
        subprocess.run([str(executable),str(root)],check=True)

if __name__=='__main__':main()
