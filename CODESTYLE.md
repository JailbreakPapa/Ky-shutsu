# WD Studios Corp. - Code Style

### Library Use

Within all WD Studios Projects, the C++ STD (Standard Libraries) are allowed in use, even in contained headers. 

The motivation for this, is to avoid obscuring functions and data types behind general types like **"void"**; **"void*""**, etc.

#### WDFramework (wdtier0)

Since we allow the C++ STD to be used, and at the same time, we actively also use our internal STD, called WDFramework; WDFramework has full interop between C++ STD and WDFramework, allowing programmers to use our types interchangeably. 


## Code Formatting

We use clang-format, and use WebKits styling rules.