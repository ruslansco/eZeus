#include "ebinaryimageloader.h"

#include <fstream>
#include <filesystem>

#include "esplitbinary.h"
#include "egamedir.h"

std::shared_ptr<eTexture> eBinaryImageLoader::load(SDL_Renderer* const r,
                                                   const std::string& path) {
    // 1. Direct match: e.g. "Textures/45/interfaceNewParts_0.png", "Textures/Zeus_Title.png"
    //    A "<name>@2x.png" sibling holds the same sheet at double pixel density
    //    (sharper when zoomed in); it takes precedence over the plain file.
    const auto basePath = eGameDir::texturesDir();
    const auto loosePath = basePath + path;
    const auto ext = loosePath.rfind(".png");
    if(ext != std::string::npos) {
        const auto hiPath = loosePath.substr(0, ext) + "@2x.png";
        if(std::filesystem::exists(hiPath)) {
            const auto tex = std::make_shared<eTexture>();
            if(tex->load(r, hiPath)) {
                tex->setDensity(2);
                printf("Loaded custom 2x texture: %s\n", hiPath.c_str());
                return tex;
            }
        }
    }
    if(std::filesystem::exists(loosePath)) {
        const auto tex = std::make_shared<eTexture>();
        if(tex->load(r, loosePath)) {
            printf("Loaded custom texture: %s\n", loosePath.c_str());
            return tex;
        }
    }

    // 2. Full-screen art & maps (Zeus_Data_Images): can be shared across all UI scales
    const auto dataImagesPos = path.find("Zeus_Data_Images/");
    if(dataImagesPos != std::string::npos) {
        const auto relDataImages = path.substr(dataImagesPos);
        const auto sharedDataImages = basePath + relDataImages;
        if(std::filesystem::exists(sharedDataImages)) {
            const auto tex = std::make_shared<eTexture>();
            if(tex->load(r, sharedDataImages)) {
                printf("Loaded custom shared texture: %s\n", sharedDataImages.c_str());
                return tex;
            }
        }
        // Also check 60/Zeus_Data_Images/ fallback
        const auto highResDataImages = basePath + "60/" + relDataImages;
        if(std::filesystem::exists(highResDataImages)) {
            const auto tex = std::make_shared<eTexture>();
            if(tex->load(r, highResDataImages)) {
                printf("Loaded custom high-res texture: %s\n", highResDataImages.c_str());
                return tex;
            }
        }
    }

    const auto it = eBinaryDataMap.find(path);
    if(it == eBinaryDataMap.end()) {
        printf("Could not find '%s' image\n", path.c_str());
        return nullptr;
    }
    const auto& bd = it->second;
    std::string epath;
    switch(bd.fFileId) {
    case eFileId::i:
        epath = eGameDir::iBinaryPath();
        break;
    case eFileId::i15:
        epath = eGameDir::i15BinaryPath();
        break;
    case eFileId::i30:
        epath = eGameDir::i30BinaryPath();
        break;
    case eFileId::i45:
        epath = eGameDir::i45BinaryPath();
        break;
    case eFileId::i60:
        epath = eGameDir::i60BinaryPath();
        break;
    }

    std::ifstream file(epath, std::ios::in | std::ios::binary);
    if(!file) {
        printf("Could not open '%s'\n", epath.c_str());
        return nullptr;
    }

    const auto data = new char[bd.fSize];
    file.seekg(bd.fPos);
    file.read(data, bd.fSize);
    file.close();
    const auto rw = SDL_RWFromMem(data, bd.fSize);
    const auto surf = IMG_Load_RW(rw, SDL_FALSE);
    if(!surf) {
        printf("Unable to load image %s! SDL_image Error: %s\n",
               path.c_str(), IMG_GetError());
        return nullptr;
    }
    delete[] data;

    const auto tex = std::make_shared<eTexture>();
    tex->load(r, surf);

    return tex;
}
