all: os_unreal.bootimg
os_unreal.bootimg: os_unreal.relloc
	ld -o os_unreal.bootimg --oformat binary -Ttext 0x0000 os_unreal.relloc
os_unreal.relloc: os_unreal.s
	as -o os_unreal.relloc os_unreal.s
run: os_unreal.bootimg
	-bochs -qf ./rc_unreal
clean: 
	-rm os_unreal.relloc os_unreal.bootimg parport.out log.out debugger.out

	
