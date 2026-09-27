#include "egeometrybatch.h"

#include <vector>

namespace {
    struct eBucket {
        SDL_Texture* fTex = nullptr;
        std::vector<SDL_Vertex> fVerts;
        std::vector<int> fIds;
    };

    SDL_Renderer* sRenderer = nullptr;
    // Buckets are kept between frames so their buffers keep their capacity;
    // only the first sUsed are live.
    std::vector<eBucket> sBuckets;
    int sUsed = 0;
}

static void queueGeometry(SDL_Renderer* r, SDL_Texture* tex,
                          const SDL_Vertex* v, int count,
                          const int* ids, int indexCount) {
    if(sRenderer != r) {
        eGeometryBatch::sFlush();
        sRenderer = r;
    }
    eBucket* b = nullptr;
    for(int i = 0; i < sUsed; i++) {
        if(sBuckets[i].fTex == tex) {
            b = &sBuckets[i];
            break;
        }
    }
    if(!b) {
        if(sUsed == static_cast<int>(sBuckets.size())) sBuckets.emplace_back();
        b = &sBuckets[sUsed++];
        b->fTex = tex;
    }
    const int base = b->fVerts.size();
    b->fVerts.insert(b->fVerts.end(), v, v + count);
    for(int i=0;i<indexCount;++i) b->fIds.push_back(base+ids[i]);
}

void eGeometryBatch::sQueueQuad(SDL_Renderer* r, SDL_Texture* tex, const SDL_Vertex v[4]) {
    static const int ids[6] = {0,1,2,0,2,3};
    queueGeometry(r,tex,v,4,ids,6);
}

void eGeometryBatch::sQueueFan(SDL_Renderer* r, SDL_Texture* tex, const SDL_Vertex v[5]) {
    static const int ids[12] = {4,0,1,4,1,2,4,2,3,4,3,0};
    queueGeometry(r,tex,v,5,ids,12);
}

void eGeometryBatch::sFlush() {
    if(sUsed == 0) return;
    for(int i = 0; i < sUsed; i++) {
        auto& b = sBuckets[i];
        SDL_RenderGeometry(sRenderer, b.fTex,
                           b.fVerts.data(), b.fVerts.size(),
                           b.fIds.data(), b.fIds.size());
        b.fVerts.clear();
        b.fIds.clear();
        b.fTex = nullptr;
    }
    sUsed = 0;
}
