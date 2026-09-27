#ifndef EWALKERPRESENTATION_H
#define EWALKERPRESENTATION_H

#include <algorithm>
#include <cmath>

// Transient display state, deliberately absent from save files and simulation.
// Capture once around the OUTER 50 ms tick, including all fast-forward substeps.
class eWalkerPresentation {
public:
    void begin(double x, double y, double time) {
        if(!mReady) reset(x,y,time);
        mPX=x; mPY=y; mPT=time; mPD=mDistance; mAlpha=0;
    }
    void travel(double distance) { mDistance += std::max(0.0,distance); }
    void end(double x, double y, double time) {
        if(!mReady || std::hypot(x-mPX,y-mPY) > mDistance-mPD+.001) {
            reset(x,y,time); // spawn, load or teleport: never streak across the map
            return;
        }
        mX=x; mY=y; mTime=time;
    }
    void reset(double x, double y, double time) {
        mPX=mX=x; mPY=mY=y; mPT=mTime=time; mPD=mDistance;
        mReady=true; mAlpha=1;
    }
    // A pause settles the interval at 1; resuming must never move it backwards.
    void sample(double alpha) { mAlpha=std::max(mAlpha,std::clamp(alpha,0.0,1.0)); }
    bool ready() const { return mReady; }
    double x() const { return mix(mPX,mX); }
    double y() const { return mix(mPY,mY); }
    double time() const { return mix(mPT,mTime); }
    double distance() const { return mix(mPD,mDistance); }
    int walkFrame(int frames, double stride) const {
        return int(std::floor(distance()/stride*frames+1e-8))%frames;
    }
private:
    double mix(double a,double b) const { return a+(b-a)*mAlpha; }
    bool mReady=false;
    double mPX=0,mPY=0,mX=0,mY=0,mPT=0,mTime=0,mPD=0,mDistance=0,mAlpha=1;
};
#endif
