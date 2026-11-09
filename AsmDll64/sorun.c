#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include <string.h>

#define MAXARGS 64

//extern int asm_call_implicit_function(void*,int,int*);
extern int asm_call_implicit_function(long,long,long,long);

int main(int lb, char** par)
{
 asm_call_implicit_function(1001LL, 1002LL, 1003LL, 1004LL); 
 void* handle;
 void* fhandle;
 int ch,nargs;
 int* argptr;
 char *path, *proc;
 path=proc=NULL;
 nargs=0;
 argptr = (int*)malloc(MAXARGS<<2);
 if (!argptr) { printf("malloc failed!\n"); exit(1); }
 if (lb<3) 
   {
    printf("%s:-f dyn_lib_name -p proc_name -i 4BYTEPTR [-i...]\n",par[0]); 
    return 1;
   }
 while ((ch = getopt(lb,par,"f:p:i:")) != -1)
   {
    switch (ch)
      {
       /* case 'd': depth = atoi(optarg); break; */
       case 'f': path  = malloc(strlen(optarg)+1); strcpy(path, optarg); break;
       case 'p': proc  = malloc(strlen(optarg)+1); strcpy(proc, optarg); break;
       case 'i': argptr[nargs] = atoi(optarg); nargs++; 
		 if (nargs>MAXARGS) { printf("Too much args.\n"); exit(1); }
		 break;
      }
   }
 if (!proc) return 1;  
 if (path) handle = dlopen(path, RTLD_LAZY|RTLD_GLOBAL);
 else      handle = dlopen("/usr/lib/libc.so", RTLD_LAZY|RTLD_GLOBAL);
 if (!handle) { puts(dlerror()); exit(1); }
 fhandle = dlsym(handle,proc);
 if (!fhandle)
   {
    fhandle = dlsym(RTLD_SELF,proc);
    if (!fhandle) { puts(dlerror()); exit(1); }
   }
 //ch=asm_call_implicit_function(&fhandle,nargs,argptr); 
 //ch=asm_call_implicit_function(1024LL,2048,3072LL); 
 printf("\nreturned: %d (as int32)\n", ch);
 if (dlclose(handle)==-1) puts(dlerror());
 free(path);
 free(proc);
 free(argptr);
 return 0;
}

