* Block 底层解析
    * 什么是block?
        * block编译转换结构
        * block实际结构
    * block的类型
        * NSConcreteGlobalBlock和NSConcreteStackBlock
        * NSConcreteMallocBlock
        * 三种类型block测试(MRC)
    * 捕捉变量对block结构的影响
        * 局部变量
        * 全局变量
        * 局部静态变量
        * __block修饰的变量
        * self隐式循环引用
        * ObjC对象(MRC)
        * Block中使用的ObjC对象的行为(MRC)
    * 不同类型block的复制
        * Block的copy、retain、release操作(MRC)
    * ARC中的block
        * block试验
        * block作为参数传递
        * block作为返回值
        * block属性
    * ARC与非ARC(MRC)下的Weak-Strong Dance
        * ARC 的Weak-Strong Dance
        * 非ARC(MRC) 的Weak-Strong Dance
        * 总结
* 测试Demo工程地址
* 参考文献

# Blcok 底层解析
## 什么是block?
什么是block？
首先，看一个极简的block：
```
int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ^{ };
    }
    return 0;
}
```
如何声明一个block在 Objective-C ？

* As a local variable:
    ```
    returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...};
    ```
* As a property:
    ```
    @property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes);
    ```
* As a method parameter:
    ```
    - (void)someMethodThatTakesABlock:(returnType (^nullability)(parameterTypes))blockName;
    ```
* As an argument to a method call:
    ```
    [someObject someMethodThatTakesABlock:^returnType (parameters) {...}];
    ```
* As a typedef:
    ```
    typedef returnType (^TypeName)(parameterTypes);
TypeName blockName = ^returnType(parameters) {...};
    ```

### block编译转换结构

```
int myMain()
{
    ^{ } ();
    
    ^{ } ();
    
    return 0;
}
```

对其执行`clang -rewrite-objc`编译转换成C++实现，得到以下代码：

![](http://7xraw1.com1.z0.glb.clouddn.com/what_is_block.jpg)

### block的实际结构

关于block的数据结构和runtime是开源的，可以在llvm项目看到，或者下载苹果的[libclosure](http://opensource.apple.com//tarballs/libclosure/)库的源码来看。苹果也提供了[在线的代码查看方式](http://opensource.apple.com/source/libclosure/libclosure-63/)，其中包含了很多示例和文档说明。

接下来观察下Block_private.h文件中对block的相关结构体的真实定义：

![](http://7xraw1.com1.z0.glb.clouddn.com/block_layout.jpg)

* invoke，同上文的FuncPtr，block执行时调用的函数指针，block定义时内部的执行代码都在这个函数中
* Block_descriptor，block的详细描述

总体来说，block就是一个里面存储了指向`函数体中包含定义block时的代码块`的函数指针，以及`block外部上下文`变量等信息的结构体。

## block的类型

在block runtime中，定义了6种类：

![](http://7xraw1.com1.z0.glb.clouddn.com/block_type.png)

![](http://7xraw1.com1.z0.glb.clouddn.com/block_type2.png)

* _NSConcreteStackBlock         栈上创建的block
* _NSConcreteMallocBlock        堆上创建的block
* _NSConcreteGlobalBlock        作为全局变量的block
* _NSConcreteWeakBlockVariable
* _NSConcreteAutoBlock
* _NSConcreteFinalizingBlock

其中我们能接触到的主要是前3种，后三种用于GC，咱们就先不看了。

block的常见类型有3种：

* _NSConcreteGlobalBlock（全局）
* _NSConcreteStackBlock（栈）
* _NSConcreteMallocBlock（堆）

APUE(Unix环境高级编程)的进程虚拟内存段分布图：

![](http://7xraw1.com1.z0.glb.clouddn.com/AUPE.png)

其中前2种在Block.h种声明，后1种在Block_private.h中声明。

### NSConcreteGlobalBlock和NSConcreteStackBlock

首先，根据前面两种类型，编写以下代码：

```
void (^globalBlock)() = ^{
    
};


int block_type_Main()
{
    void (^stackBlock1)() = ^{
        
    };
    
    stackBlock1();
    globalBlock();
    
    return 0;
}
```
对其进行编译转换后得到以下代码：

![](http://7xraw1.com1.z0.glb.clouddn.com/block_type_cpp.jpg)

可以看出globalBlock的isa指向了_NSConcreteGlobalBlock，即在全局区域创建，编译时就已经确定了，位于上图中的代码段；stackBlock的isa指向了_NSConcreteStackBlock，即在栈区创建。

### NSConcreteMallocBlock

堆中的block无法直接创建，其需要由_NSConcreteStackBlock类型的block拷贝而来(也就是说block需要执行copy之后才能存放到堆中)。由于block的拷贝最终都会调用_Block_copy_internal函数，所以观察这个函数就可以知道堆中block是如何被创建的了：
![](http://7xraw1.com1.z0.glb.clouddn.com/malloc_block.jpg)

### 三种类型block测试(MRC)
```
#import "block_in_MRC.h"

typedef long (^BlkSum)(int, int);


@implementation block_in_MRC
+ (void)main
{
    BlkSum blk1 = ^ long (int a, int b) {
        return a + b;
    };
    NSLog(@"blk1 = %@", blk1);// blk1 = <__NSGlobalBlock__: 0x47d0>
    
    
    int base = 100;
    BlkSum blk2 = ^ long (int a, int b) {
        return base + a + b;
    };
    NSLog(@"blk2 = %@", blk2); // blk2 = <__NSStackBlock__: 0xbfffddf8>
    
    BlkSum blk3 = [[blk2 copy] autorelease];
    NSLog(@"blk3 = %@", blk3); // blk3 = <__NSMallocBlock__: 0x902fda0>
}
@end
```

## 捕捉变量对block结构的影响
编译转换捕捉不同变量类型的block，以对比它们的区别。
### 局部变量
代码

```
// 局部变量

int capture_var_effect_block_Main()
{
    
    int a;
    ^{a;};
    
    // 报错  var is not assignable(missing __block type specifier)
//    ^{a = 10;};
    
    return 0;
}
```

对其进行编译转换后得到以下代码(注释不会被编译)：

![](http://7xraw1.com1.z0.glb.clouddn.com/capture_var_effect_block_cpp.jpg)

我们通过指针传递

```
int test()
{
    int a = 0;
    // 利用指针p存储a的地址
    int *p = &a;
    
    ^{
        // 通过a的地址设置a的值
        *p = 10;
    }();
    
   return 0;
}
```
变量a的生命周期是和方法test的栈相关联的，当test运行结束，栈随之销毁，那么变量a就会被销毁，p也就成为了野指针。如果block是作为参数或者返回值，这些类型都是跨栈的，也就是说再次调用会造成野指针错误。

### 全局变量
代码
```
// 全局静态
static int a;
// 全局
int b;

int capture_global_var_effect_block()
{
    ^{
        a = 10;
        b = 10;
    }();
    
    return 0;
}
```
编译转换后

![](http://7xraw1.com1.z0.glb.clouddn.com/capture_global_var_effect_block_cpp.jpg)

直接使用了a，b变量；

### 局部静态变量 
代码
```
int capture_local_var_effect_block()
{
    static int a;
    // 静态局部变量是存储在静态数据存储区域的，也就是和程序拥有一样的生命周期，也就是说在程序运行时，都能够保证block访问到一个有效的变量。但是其作用范围还是局限于定义它的函数中，所以只能在block通过静态局部变量的地址来进行访问。
    ^{
        a = 10;
    }();
    
    return 0;
}
```

编译转换后
![](http://7xraw1.com1.z0.glb.clouddn.com/capture_local_var_effect_block_new_cpp.jpg)

### __block修饰的变量

代码

```
    int __block_modify_var()
    {
        __block int a;
        
        ^{
            a = 10;
        }();
        
        return 0;
    }
```

编译转换后

![](http://7xraw1.com1.z0.glb.clouddn.com/__block_modify_var_cpp.jpg)

runtime.c _Block_byref_assign_copy 方法

![](http://7xraw1.com1.z0.glb.clouddn.com/runtime_Block_byref_assign_copy_func.jpg)

### self隐式循环引用
代码

```
@implementation self_hidden_retain_cycle
{
    int _a;
    void (^_block)();
}

- (void)test
{
    void (^_block)() = ^{
        _a = 10;
    };
}
@end
```

编译转换后
![](http://7xraw1.com1.z0.glb.clouddn.com/self_hidden_retain_cycle_cpp.jpg)

### ObjC对象(MRC)
代码
```
@interface MyClass : NSObject {
    NSObject* _instanceObj;
}
@end

@implementation MyClass

NSObject* __globalObj = nil;

- (id) init {
    if (self = [super init]) {
        _instanceObj = [[NSObject alloc] init];
    }
    return self;
}

- (void) test {
    static NSObject* __staticObj = nil;
    __globalObj = [[NSObject alloc] init];
    __staticObj = [[NSObject alloc] init];

    NSObject* localObj = [[NSObject alloc] init];
    __block NSObject* blockObj = [[NSObject alloc] init];

    typedef void (^MyBlock)(void) ;
    MyBlock aBlock = ^{
        NSLog(@"%@", __globalObj);
        NSLog(@"%@", __staticObj);
        NSLog(@"%@", _instanceObj);
        NSLog(@"%@", localObj);
        NSLog(@"%@", blockObj);
    };
    aBlock = [[aBlock copy] autorelease];
    aBlock();

    NSLog(@"%d", [__globalObj retainCount]);
    NSLog(@"%d", [__staticObj retainCount]);
    NSLog(@"%d", [_instanceObj retainCount]);
    NSLog(@"%d", [localObj retainCount]);
    NSLog(@"%d", [blockObj retainCount]);
}
@end

```

执行结果为1 1 1 2 1。

__globalObj和__staticObj在内存中的位置是确定的，所以Block copy时不会retain对象。

_instanceObj在Block copy时也没有直接retain _instanceObj对象本身，但会retain self。所以在Block中可以直接读写_instanceObj变量。

localObj在Block copy时，系统自动retain对象，增加其引用计数。

blockObj在Block copy时也不会retain。

非ObjC对象，如GCD队列dispatch_queue_t。Block copy时并不会自动增加他的引用计数。

### Block中使用的ObjC对象的行为
```
@property (nonatomic, copy) void(^myBlock)(void);

block_in_MRC* obj = [[[block_in_MRC alloc] init] autorelease];
    self.myBlock = ^ {
        //  obj doSomething
    };
```
对象obj在Block被copy到堆上的时候自动retain了一次。因为Block不知道obj什么时候被释放，为了不在Block使用obj前被释放，Block retain了obj一次，在Block被释放的时候，obj被release一次。


## 不同类型block的复制

block的复制代码在_Block_copy_internal函数中。

![](http://7xraw1.com1.z0.glb.clouddn.com/block_type_copy.jpg)

### Block的copy、retain、release操作(MRC)
```
+ (void)test
{
    int base = 100;
    BlkSum blk2 = ^ long (int a, int b) {
        return base + a + b;
    };
    NSLog(@"blk2 = %@", blk2); // blk2 = <__NSStackBlock__: 0xbfffddf8>
    
    BlkSum blk3 = [[[[[blk2 copy] copy] copy] copy] copy];
    NSLog(@"blk3 = %@", blk3); // blk3 = <__NSMallocBlock__: 0x902fda0>
    NSLog(@"blk3 retainCount = %@", @([blk3 retainCount]));// blk3 retainCount = 1

    
    BlkSum blk4 = [blk2 copy];
    [blk4 retain];
    NSLog(@"blk4 retainCount = %@", @([blk4 retainCount]));// blk4 retainCount = 1
    [blk4 release];
    NSLog(@"blk4 retainCount = %@", @([blk4 retainCount]));// blk4 retainCount = 1
}

```
Block_release in runtime.c

![](http://7xraw1.com1.z0.glb.clouddn.com/block_release.jpg)

* 对Block不管是retain、copy、release都不会改变引用计数retainCount，retainCount始终是1；
* NSGlobalBlock：retain、copy、release操作都无效；
* NSStackBlock：retain、release操作无效，必须注意的是，NSStackBlock在函数返回后，Block内存将被回收。即使retain也没用。容易犯的错误是[[mutableAarry addObject:stackBlock]，在函数出栈后，从mutableAarry中取到的stackBlock已经被回收，变成了野指针。正确的做法是先将stackBlock copy到堆上，然后加入数组：[mutableAarry addObject:[[stackBlock copy] autorelease]]。支持copy，copy之后生成新的NSMallocBlock类型对象。
* NSMallocBlock支持retain、release，虽然retainCount始终是1，但内存管理器中仍然会增加、减少计数。copy之后不会生成新的对象，只是增加了一次引用，类似retain；

## ARC中的block
![](http://7xraw1.com1.z0.glb.clouddn.com/block_in_ARC.png)

[苹果文档](https://developer.apple.com/library/mac/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)提及，在ARC模式下，在栈间传递block时，不需要手动copy栈中的block，即可让block正常工作。主要原因是ARC对栈中的block自动执行了copy，将_NSConcreteStackBlock类型的block转换成了_NSConcreteMallocBlock的block。

### block 实验
```
+ (void)main
{
    int i = 10;
    void (^block)() = ^{i;};
    
    __weak void (^weakBlock)() = ^{i;};
    
    void (^stackBlock)() = ^{};
    
    // ARC情况下
    
    // 创建时，都会在栈中
    // <__NSStackBlock__: 0x7fff5fbff730>
    NSLog(@"%@", ^{i;});
    
    // 因为stackBlock为strong类型，且捕获了外部变量，所以赋值时，自动进行了copy
    // <__NSMallocBlock__: 0x100206920>
    NSLog(@"%@", block);
    
    // 如果是weak类型的block，依然不会自动进行copy
    // <__NSStackBlock__: 0x7fff5fbff728>
    NSLog(@"%@", weakBlock);
    
    // 如果block是strong类型，并且没有捕获外部变量，那么就会转换成__NSGlobalBlock__
    // <__NSGlobalBlock__: 0x100001110>
    NSLog(@"%@", stackBlock);
    
    // 在非ARC情况下，产生以下输出
    // <__NSStackBlock__: 0x7fff5fbff6d0>
    // <__NSStackBlock__: 0x7fff5fbff730>
    // <__NSStackBlock__: 0x7fff5fbff700>
    // <__NSGlobalBlock__: 0x1000010d0>
}

```

可以看出，ARC对类型为strong且捕获了外部变量的block进行了copy。并且当block类型为strong，但是创建时没有捕获外部变量，block最终会变成__NSGlobalBlock__类型（这里可能因为block中的代码没有捕获外部变量，所以不需要在栈中开辟变量，也就是说，在编译时，这个block的所有内容已经在代码段中生成了，所以就把block的类型转换为全局类型）

### block作为参数传递

在栈中的block需要注意的情况：
```
NSMutableArray *arrayM;

void myBlock()
{
    int a = 5;
    Block block = ^ {
        NSLog(@"%d", a);
    };
    
    [arrayM addObject:block];
    NSLog(@"%@", block);
}

+ (void)test
{
    arrayM = @[].mutableCopy;
    
    myBlock();
    
    Block block = [arrayM firstObject];
    // 非ARC这里崩溃
    block();
}
```
可以看到，ARC情况下因为自动执行了copy，所以返回类型为__NSMallocBlock__，在函数结束后依然可以访问；而非ARC情况下，需要我们手动调用[block copy]来将block拷贝到堆中，否则因为栈中的block生命周期和函数中的栈生命周期关联，当函数退出后，相应的堆被销毁，block也就不存在了。
如果把block的以下代码删除：
```
NSLog(@"%d", a);
```
那么block就会变成全局类型，在test中访问也不会出崩溃。

### block作为返回值

在非ARC情况下，如果返回值是block，则一般这样操作：

```
return [[block copy] autorelease];
```
对于外部要使用的block，更趋向于把它拷贝到堆中，使其脱离栈生命周期的约束。

### block属性

这里还有一点关于block类型的ARC属性。上文也说明了，ARC会自动帮strong类型且捕获外部变量的block进行copy，所以在定义block类型的属性时也可以使用strong，不一定使用copy。也就是以下代码：
```
/** 假如有栈block赋给以下两个属性 **/

// 这里因为ARC，当栈block中会捕获外部变量时，这个block会被copy进堆中
// 如果没有捕获外部变量，这个block会变为全局类型
// 不管怎么样，它都脱离了栈生命周期的约束

@property (strong, nonatomic) Block *strongBlock;

// 这里都会被copy进堆中
@property (copy, nonatomic) Block *copyBlock;
```

## ARC与非ARC(MRC)下的Weak-Strong Dance

### ARC

在使用block过程中，经常会遇到`retain cycle`的问题，例如：

```
- (void)dealloc  
{  
  [[NSNotificationCenter defaultCenter] removeObserver:_observer];  
}  

- (void)loadView  
{  

  [super loadView];  

  _observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"testKey"  
                                                                object:nil  
                                                                 queue:nil  
                                                            usingBlock:^(NSNotification *note) {  
      [self dismissModalViewControllerAnimated:YES];    
  }];  
}
```

在block中用到了self，self会被block retain，而_observer会copy一份该block，就是说_observer间接持有self，同时当前的self也会retain _observer，最终导致self持有_observer，_observer持有self，形成`retain cycle`。

对于在block中的`retain cycle`，在2011 WWDC Session #322 (Objective-C Advancements in Depth)有一个解决方案`weak-strong dance`，很漂亮的名字。其实现如下：

```
- (void)dealloc  
{  
  [[NSNotificationCenter defaultCenter] removeObserver:_observer];  
}  

- (void)loadView  
{  
  [super loadView];  
  __weak TestViewController *wself = self;  
  _observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"testKey"  
                                                                object:nil  
                                                                 queue:nil  
                                                            usingBlock:^(NSNotification *note) {  
      __strong TestViewController *sself = wself;  
      [sself dismissModalViewControllerAnimated:YES];  
  }];  
}
```
在block中使用self之前先用一个`__weak`变量引用self，导致block不会retain self，打破retain cycle，然后在block中使用wself之前先用`__strong`类型变量引用wself，以确保使用过程中不会dealloc。简而言之就是推迟对self的retain，在使用时才进行retain。这有点像lazy loading的意思。

注：iOS5以下没有`__weak`，则需使用`__unsafe_unretained`。


### 非ARC(MRC)

在非ARC环境中，显然之前的使用的`__weak`或`__unsafe_unretained`将会是无效的，那么我们需使用另外一种方法来代替，这里就需要用到`__block`。

`__block`在ARC和非ARC中有点细微的差别（[Automatic Reference Counting : Blocks](http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html)）：

*  在ARC中，`__block`会自动进行retain

    ```
    // ARC 中 `__block`会自动进行retain 实验
    + (void)test__Block
    {
        // You can use CFGetRetainCount with Objective-C objects, even under ARC:
        NSObject *objc = [[NSObject alloc] init];
        NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
        __block NSObject *objcNew = objc;
        NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
    }
    // 输出
    // test__Block-- objc Retain count is 1
    // test__Block-- objc Retain count is 2
    
    ```
*  在非ARC中，`__block`不会自动进行retain
    
    ```
    // 在MRC中 __block不会自动进行retain
    + (void)test__Block
    {
        // You can use CFGetRetainCount with Objective-C objects, even under ARC:
        NSObject *objc = [[NSObject alloc] init];
        NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
        __block NSObject *objcNew = objc;
        NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
    }
    // 输出
    // test__Block-- objc Retain count is 1
    // test__Block-- objc Retain count is 1
    ```

因此首先要注意的一点就是用`__block`打破`retain cycle`的方法仅在非ARC下有效，下面是非ARC的`weak-strong dance`：

```
- (void)dealloc  
{  
  [[NSNotificationCenter defaultCenter] removeObserver:_observer];  
  [_observer release];  
  [super dealloc];  
}  

- (void)loadView  
{  
  [super loadView];  
  __block TestViewController *bself = self;  
  _observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"testKey"  
                                                                object:nil  
                                                                 queue:nil  
                                                               ngBlock:^(NSNotification *note) {  

      [bself retain];  
      [bself dismissModalViewControllerAnimated:YES];  
      [bself release];  

  }];  
}
```

将self赋值为`__block`类型变量，在非ARC中`__block`类型变量不会进行retain，从而打破retain cycle，然后在使用bself前进行retain，以确保在使用过程中不会dealloc 。

### 总结

打破循环引用：

*  ARC下： __week
*  非ARC（MRC）下：__block

__block的作用：

非ARC（MRC）下

1. 说明变量可改
2. 说明指针指向的对象不做隐式retain操作。

ARC下只有1。
# 测试Demo工程地址
[block_learning]()

# 参考文献
* [How Do I Declare A Block in Objective-C?](http://fuckingblocksyntax.com/)
* [Block技巧与底层解析](http://triplecc.github.io/blog/2015-07-19-blockji-qiao-yu-di-ceng-jie-xi/)
*  [谈Objective-C block的实现](http://blog.devtang.com/2013/07/28/a-look-inside-blocks/)
* [正确使用Block避免Cycle Retain和Crash](http://tanqisen.github.io/blog/2013/04/19/gcd-block-cycle-retain/)
* [objc 中的 block](http://blog.ibireme.com/2013/11/27/objc-block/)
* [Block Apple Source Code Browser ](http://opensource.apple.com/source/libclosure/libclosure-63/)
* 《Objective-C 高级编程》



