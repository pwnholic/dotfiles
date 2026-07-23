# NVIDIA CUDA toolkit environment for development.
#
# Fish does NOT source /etc/profile.d/*.sh, so the variables normally exported
# by the Arch `cuda` package (via /etc/profile.d/cuda.sh, which only bash/zsh
# read) are not applied here. We set the equivalent ourselves, guarded on
# /opt/cuda existing.
#
# Install the toolkit on CachyOS/Arch:   sudo pacman -S cuda
# The RTX 5050 is a Blackwell GPU (compute capability sm_120) and requires
# CUDA >= 12.8; the installed driver (610.x) supports current CUDA releases.

if test -d /opt/cuda
    set -gx CUDA_HOME /opt/cuda
    set -gx CUDA_PATH /opt/cuda

    # nvcc + nsight tools.
    fish_add_path --path $CUDA_HOME/bin $CUDA_HOME/nsight-compute/latest $CUDA_HOME/nsight-systems/bin

    # Runtime libs + CUPTI. A global LD_LIBRARY_PATH can cause library conflicts;
    # remove this block if you prefer rpath-based linking.
    set -l cuda_libs $CUDA_HOME/lib64 $CUDA_HOME/extras/CUPTI/lib64
    if set -q LD_LIBRARY_PATH; and test -n "$LD_LIBRARY_PATH"
        set -gx LD_LIBRARY_PATH $LD_LIBRARY_PATH $cuda_libs
    else
        set -gx LD_LIBRARY_PATH $cuda_libs
    end
end
