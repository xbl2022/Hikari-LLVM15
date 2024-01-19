# Hikari-LLVM15
 A fork of HikariObfuscator [WIP]
 
 ## 原项目链接
 [https://github.com/HikariObfuscator/Hikari](https://github.com/HikariObfuscator/Hikari)

## 使用

下载后编译

### Swift混淆支持

由于Xcode的LLVM相比原版LLVM有大量闭源改动，Hanabi在Xcode 15起已无法编译Swift。

使用[Swift Toolchain](https://github.com/61bcdefg/Hikari-Swift)。

需要注意的是添加混淆参数的位置是在**Swift Compiler - Other Flags**中的**Other Swift Flags**，并且是在前面加-Xllvm，而不是-mllvm。
关闭优化的地方在**Swift Compiler - Code Generation**中的**Optimization Level**，设置为 *No Optimization [-Onone]*

每次修改Other Swift Flags后编译前需要先Shift+Command+K(Clean Build Folder)，因为Swift并不会像OC一样检测到项目cflag的修改就会重新编译

### PreCompiled IR

PreCompiled IR是指自定义的LLVM Bitcode文件，可以通过在存在回调函数的源文件的编译命令(C Flags)中加上`-emit-llvm`生成，然后放到指定位置即可

###  一些修改

#### AntiClassDump

arm64e支持

#### BogusControlFlow

跳过包含MustTailCall的基本块以避免错误

跳过presplit coroutine和包含CoroBeginInst的基本块以支持swift、

修复了消失的不透明谓词

#### Flattening

跳过presplit coroutine以支持swift

间接修改状态变量，可以使部分脚本无法正常反混淆（如d810）

#### FunctionCallObfuscate

将只会在启用混淆的地方混淆Objc Call，而不是整个模块

#### FunctionWrapper

跳过一些目前无法处理的函数以支持swift

支持混淆包含byval的函数（可能？）

#### SplitBasicBlocks

修复了可能的堆污染错误

#### StringEncryption

支持混淆在结构体和数组中的字符串

arm64e支持

#### Substitution

添加更多pattern

#### IndirectBranch

运行后会重排列基本块的顺序

默认启用基于栈的跳转，可以使静态分析更困难

###  混淆选项

这里只会介绍修改的部分，原项目存在的功能请自行前往[https://github.com/HikariObfuscator/Hikari/wiki/](https://github.com/HikariObfuscator/Hikari/wiki/)查看

#### AntiClassDump

-acd-rename-methodimp

重命名在IDA中显示的方法函数名称(修改为ACDMethodIMP)，不是修改方法名。默认关闭

#### AntiHooking

整体开启这个功能会使生成的二进制文件大小急剧膨胀，建议只在部分函数开启这个功能(toObfuscate)

支持检测Objective-C运行时Hook。如果检测到就会调用AHCallBack函数(从PreCompiled IR获取)，如果不存在AHCallBack，就会退出程序。

InlineHook检测目前只支持arm64，在函数中插入代码检测当前函数是否被Hook，如果检测到就会调用AHCallBack函数(从PreCompiled IR获取)，如果不存在AHCallBack，就会退出程序。

-enable-antihook

启用AntiHooking。默认关闭

-ah_inline

检测当前函数是否被inline hook。默认开启

-ah_objcruntime

检测当前函数是否被runtime hook。默认开启

-ah_antirebind

使生成的文件无法被fishhook重绑定符号。默认关闭

-adhexrirpath

AntiHooking PreCompiled IR文件的路径

#### AntiDebugging

自动在函数中进行反调试，如果有InitADB和ADBCallBack函数(从PreCompiled IR获取)，就会调用ADBInit函数，如果不存在InitADB和ADBCallBack函数并且是Apple ARM64平台，就会自动在void返回类型的函数中插入内联汇编反调试，否则不做处理。

-enable-adb

启用AntiDebugging。默认关闭

-adb_prob

每个函数被添加反调试的概率。默认为40

-adbextirpath

AntiDebugging PreCompiled IR文件的路径

#### StringEncryption

-strcry_prob

每个字符串中每个byte被加密的概率。默认为100。这个功能是为了给一些需要的加密强度不高，但是重视体积的人。

#### BogusControlFlow

-bcf_onlyjunkasm

在虚假块中只插入花指令

-bcf_junkasm

在虚假块中插入花指令，干扰IDA对函数的识别。默认关闭

-bcf_junkasm_minnum

在虚假块中花指令的最小数量。默认为2

-bcf_junkasm_maxnum

在虚假块中花指令的最大数量。默认为4

-bcf_createfunc

使用函数封装不透明谓词。默认关闭

#### ConstantEncryption

修改自https://iosre.com/t/llvm-llvm/11132

对能够处理的指令中使用的常量数字(ConstantInt)进行异或加密

-enable-constenc

启用ConstantEncryption。默认关闭

-constenc_times

ConstantEncryption在每个函数混淆的次数。默认为1

-constenc_prob

每个指令被ConstantEncryption混淆的概率。默认为50

-constenc_togv

将常量数字(ConstantInt)替换为全局变量，以及把类型为整数的二进制运算符(BinaryOperator)的运算结果替换为全局变量。默认关闭

-constenc_subxor

替换ConstantEncryption的异或运算，使其变得更加复杂

#### IndirectBranch

-indibran-use-stack

将跳转表的地址在Entry Block加载到栈中，每个基本块再从栈中读取。默认开启

-indibran-enc-jump-target

加密跳转表和索引。默认关闭

### Functions Annotations

#### Supported Options
##### C++/C functions
For example, if you have multiple functions, but you only want to obfuscate the function int foo() with indibran-use-stack enabled, you can declare it like this:
```
int foo() __attribute((__annotate__(("indibran_use_stack"))));
int foo() {
   return 2;
}
```
If you only want to obfuscate the function int foo() without using indibran-use-stack, you can declare it like this:
```
int foo() __attribute((__annotate__(("noindibran_use_stack"))));
int foo() {
   return 2;
}
```
If you only wanted the BogusControlFlow of function int foo() to be obfuscated with a probability of 100, you can declare it like this:
```
int foo() __attribute((__annotate__(("bcf_prob=100"))));
int foo() {
   return 2;
}
```
##### ObjC Methods
For example you want to pass indibran-use-stack like the C++/C example:
```
extern void hikari_indibran_use_stack(void);
@implementation foo2 : NSObject
+(void)foo{
  hikari_indibran_use_stack();
  NSLog(@"FOOOO2");
}
@end
```
If you only wanted the BogusControlFlow of function int foo() to be obfuscated with a probability of 100:
```
extern void hikari_bcf_prob(uint32_t);
@implementation foo2 : NSObject
+(void)foo{
  hikari_bcf_prob(100);
  NSLog(@"FOOOO2");
}
@end
```
##### Options
-   `ah_inline` 
-   `ah_objcruntime`
-   `ah_antirebind`  
-   `bcf_prob`
-   `bcf_loop`
-   `bcf_cond_compl`   
-   `bcf_onlyjunkasm`
-   `bcf_junkasm`
-   `bcf_junkasm_maxnum`
-   `bcf_junkasm_minnum`
-   `bcf_createfunc`
-   `constenc_subxor`
-   `constenc_togv`
-   `constenc_prob`
-   `constenc_times`
-   `fw_prob`
-   `indibran_use_stack`
-   `indibran_enc_jump_target`
-   `split_num`
-   `strcry_prob`
-   `sub_loop`
-   `sub_prob`

#### New Supported Flags

-   `adb` Anti Debugging
-   `antihook` Anti Hooking
-   `constenc` Constant Encryption

## License

See [https://github.com/HikariObfuscator/Hikari#license](https://github.com/HikariObfuscator/Hikari#license)

