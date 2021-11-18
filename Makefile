cc       := g++
nvcc     := nvcc
name     := pro
workdir  := workspace
srcdir   := src
objdir   := objs
defined  := -DPROD=\"sxai\"
stdcpp   := c++11
pwd      := $(abspath .)

# 导出你的环境变量值，可以在程序中使用，该功能还可以写成例如：
# export LD_LIBRARY_PATH=xxxxx，作用与你在终端中设置是一样的
export workdir srcdir objdir pwd

# 定义cpp的路径查找和依赖项mk文件
cpp_srcs := $(shell find $(srcdir) -name "*.cpp")
cpp_objs := $(cpp_srcs:.cpp=.o)
cpp_objs := $(cpp_objs:$(srcdir)/%=$(objdir)/%)
cpp_mk   := $(cpp_objs:.o=.mk)

# 定义cu文件的路径查找和依赖项mk文件
cu_srcs := $(shell find $(srcdir) -name "*.cu")
cu_objs := $(cu_srcs:.cu=.cuo)
cu_objs := $(cu_objs:$(srcdir)/%=$(objdir)/%)
cu_mk   := $(cu_objs:.cuo=.cumk)

# 定义opencv和cuda需要用到的库文件
link_opencv    := opencv_core opencv_imgproc opencv_videoio opencv_imgcodecs
link_cuda      := cudart
link_sys       := stdc++ dl
link_librarys  := $(link_opencv) $(link_cuda) $(link_sys)

# 定义cuda和opencv的库路径
lean_cuda      := /data/sxai/lean/cuda-10.2
lean_opencv    := /data/sxai/lean/opencv4.2.0

include_paths := \
    src                             \
    $(lean_opencv)/include/opencv4  \
    $(lean_cuda)/include

library_paths := \
    $(lean_opencv)/lib  \
    $(lean_cuda)/lib64

# 把库路径和头文件路径拼接起来成一个，批量自动加-I、-L、-l
run_paths     := $(foreach item,$(library_paths),-Wl,-rpath=$(item))
include_paths := $(foreach item,$(include_paths),-I$(item))
library_paths := $(foreach item,$(library_paths),-L$(item))
link_librarys := $(foreach item,$(link_librarys),-l$(item))

# 如果是其他显卡，请修改-gencode=arch=compute_75,code=sm_75为对应显卡的能力
# 显卡对应的号码参考这里：https://developer.nvidia.com/zh-cn/cuda-gpus#compute
# 如果是 jetson nano，提示找不到-m64指令，请删掉 -m64选项。不影响结果
cuda_arch_code    := -gencode=arch=compute_75,code=sm_75
cpp_compile_flags := -std=$(stdcpp) -w -g -O0 -m64 -fPIC -fopenmp -pthread $(defined)
cu_compile_flags  := -std=$(stdcpp) -w -g -O0 -m64 $(cuda_arch_code) -Xcompiler "$(cpp_compile_flags)" $(defined)
link_flags        := -pthread -fopenmp -Wl,-rpath='$$ORIGIN'

cpp_compile_flags += $(include_paths)
cu_compile_flags  += $(include_paths)
link_flags        += $(library_paths) $(link_librarys) $(run_paths)

# 如果头文件修改了，这里的指令可以让他自动编译依赖的cpp或者cu文件
ifneq ($(MAKECMDGOALS), clean)
-include $(cpp_mk) $(cu_mk)
endif

$(name)   : $(workdir)/$(name)

run       : $(name)
	@cd $(workdir) && ./$(name)

$(workdir)/$(name) : $(cpp_objs) $(cu_objs)
	@echo Link $@
	@mkdir -p $(dir $@)
	@g++ $^ -o $@ $(link_flags)

$(objdir)/%.o : $(srcdir)/%.cpp
	@echo Compile CXX $<
	@mkdir -p $(dir $@)
	@g++ -c $< -o $@ $(cpp_compile_flags)

$(objdir)/%.cuo : $(srcdir)/%.cu
	@echo Compile CUDA $<
	@mkdir -p $(dir $@)
	@nvcc -c $< -o $@ $(cu_compile_flags)

$(objdir)/%.mk : $(srcdir)/%.cpp
	@echo Compile depends CXX $<
	@mkdir -p $(dir $@)
	@g++ -M $< -MF $@ -MT $(@:.mk=.o) $(cpp_compile_flags)
    
$(objdir)/%.cumk : $(srcdir)/%.cu
	@echo Compile depends CUDA $<
	@mkdir -p $(dir $@)
	@nvcc -M $< -MF $@ -MT $(@:.cumk=.o) $(cu_compile_flags)

clean :
	@rm -rf $(objdir) $(workdir)/$(name)

.PHONY : clean $(name) run
