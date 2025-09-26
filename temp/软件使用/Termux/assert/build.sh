# mesa 25.3.0
meson configure build/ \
    --prefix=/usr \
    -Dplatforms=x11,wayland \
    -Dgallium-drivers=freedreno,virgl,zink,llvmpipe \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds=msm,kgsl \
    -Dglx=dri \
    -Dgbm=enabled \
    -Dopengl=true \
    -Degl=enabled \
    -Dgles2=enabled \
    -Dgles1=disabled \
    -Dglvnd=enabled \
    -Dllvm=enabled \
    -Dshared-llvm=enabled \
    -Dcpp_rtti=true \
    -Dgles1=disabled \
    -Dlibunwind=disabled \
    -Dmicrosoft-clc=disabled \
    -Dvalgrind=disabled \
    -Dbuildtype=release

# mesa 24.3.0
meson configure build/ \
    --prefix=/usr \
    -Dbuildtype=release \
    -Dplatforms=x11,wayland \
    -Dgallium-drivers=zink,freedreno,virgl,llvmpipe \
    -Dvulkan-drivers=freedreno \
    -Dvulkan-beta=true \
    -Dfreedreno-kmds=msm,kgsl \
    -Dgbm=enabled \
    -Dllvm=enabled \
    -Dshared-glapi=enabled \
    -Dglx=dri \
    -Dgles2=enabled \
    -Dgallium-xa=enabled \
    -Dopengl=true \
    -Degl=enabled \
    -Dglx-direct=true
