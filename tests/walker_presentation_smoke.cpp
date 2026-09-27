#include "characters/ewalkerpresentation.h"
#include <cassert>
#include <iostream>

static bool near(double a,double b) { return std::abs(a-b)<1e-8; }
int main() {
    for(int fps : {30,60,120}) {
        eWalkerPresentation p;p.reset(0,0,0);
        int tick=0;double previous=0;
        for(int frame=0;frame<=fps*3;++frame) {
            const double wall=double(frame)/fps;
            while((tick+1)*.05<=wall+1e-10) {
                p.begin(tick*.05,0,tick*10);
                p.travel(.05);++tick;p.end(tick*.05,0,tick*10);
            }
            p.sample((wall-tick*.05)/.05);
            assert(near(p.x(),std::max(0.0,wall-.05)));
            assert(p.x()+1e-9>=previous);previous=p.x();
            assert(near(p.distance(),p.x()));
            assert(p.walkFrame(24,.64)==int(std::floor(p.x()/.64*24+1e-8))%24);
        }
    }
    eWalkerPresentation p;p.reset(.98,.98,0);p.begin(.98,.98,0);
    p.travel(std::hypot(.06,.06));p.end(1.04,1.04,10);p.sample(.5);
    assert(near(p.x(),1.01)&&near(p.y(),1.01)); // continuous across tile edges
    p.sample(1);const double paused=p.x();p.sample(.1);assert(near(p.x(),paused));
    p.begin(1.04,1.04,10);p.travel(.1);p.end(1.14,1.04,20);p.sample(.5);
    assert(near(p.x(),1.09)); // safe resume and a corner
    p.begin(1.14,1.04,20);p.end(50,50,30);p.sample(.3);
    assert(near(p.x(),50)&&near(p.y(),50)); // teleport snaps; adds no gait distance
    p.begin(50,50,30);for(int i=0;i<5;++i)p.travel(.5);
    p.end(52.5,50,530);p.sample(.5);assert(near(p.x(),51.25));
    p.begin(52.5,50,530);p.end(52.5,50,530);p.sample(.5);
    assert(near(p.x(),52.5)&&near(p.time(),530));
    std::cout<<"PASS: 30/60/120 Hz interpolation, tile boundaries, turns, pause/resume, teleport, fast-forward and distance phase\n";
}
