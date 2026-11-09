#include "lib.h"

void call_from_lib()
{
 printf("Hello from Dll\n");
}
void call_from_lib2(int a, int b)
{
 printf("hello from dll: %d,%d\n",a,b);
}
void call_from_lib1(int a)
{
 printf("hello from dll: %d\n",a);
}

void call_from_lib3(int a, int b, int c)
{
 printf("hello from dll: %d,%d,%d\n",a,b,c);
}

int call_from_lib4(int a, int b, int c, int d)
{
 printf("hello from dll: %d,%d,%d,%d\n",a,b,c,d);
 return a+b+c+d;
}
