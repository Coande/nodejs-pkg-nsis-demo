; 逻辑符号需要该模块，如：${If}
!include "LogicLib.nsh"

; define the name of the installer
Outfile "installer.exe"
 
; 指定默认安装目录。如果不以斜杠结尾，用户选择其他目录后会自动追加文件夹
InstallDir "$PROGRAMFILES\test-service"

; We need some pages.
; 显示选择安装目录相关功能
Page directory
; 显示最终安装相关功能（当前情况下，没有这个的话，没有安装按钮）
Page instfiles



; 移除服务的函数
Function removeService

	; Check if the service exists
	SimpleSC::ExistsService "test-service"
	Pop $0 ; returns an errorcode if the service doesn´t exists (<>0)/service exists (0)

	${If} $0 == 0

		SimpleSC::StopService "test-service" 1 30
		
		DetailPrint "Removing service..."
		; Remove a service
		SimpleSC::RemoveService "test-service"
		Pop $0 ; returns an errorcode (<>0) otherwise success (0)

		${If} $0 != 0
			SimpleSC::GetErrorMessage
			Pop $0
			DetailPrint "Removing fails: $0"
		${Else}
			DetailPrint "Removing success"
		${EndIf}
	${EndIf}

FunctionEnd



; 移除服务的函数（同上，但是由于 Uninstall Section 中必须使用 un. 开头的 Function，所以拷贝了一份）
; 共用一个方法可以参考 https://nsis.sourceforge.io/Sharing_functions_between_Installer_and_Uninstaller
Function un.removeService

	; Check if the service exists
	SimpleSC::ExistsService "test-service"
	Pop $0 ; returns an errorcode if the service doesn´t exists (<>0)/service exists (0)

	${If} $0 == 0

		SimpleSC::StopService "test-service" 1 30
		
		DetailPrint "Removing service..."
		; Remove a service
		SimpleSC::RemoveService "test-service"
		Pop $0 ; returns an errorcode (<>0) otherwise success (0)
		${If} $0 != 0
			SimpleSC::GetErrorMessage
			Pop $0
			DetailPrint "Remove service fail: $0"
		${Else}
			DetailPrint "Remove service success!"
		${EndIf}
	${EndIf}

FunctionEnd



; nsis 初始化时的钩子函数
Function .onInit

	; 安装前先移除服务
	Call removeService

FunctionEnd
 
 

# default section
Section
 
	# define the output path for this file
	SetOutPath $INSTDIR
	 
	# define what to install and place it in the output path
	File index.exe
	File srvany.exe

	DetailPrint "Installing service..."

	; 把 srvany.exe 辅助程序添加为服务
	; Install a service - ServiceType own process - StartType automatic - NoDependencies - Logon as System Account
	SimpleSC::InstallService "test-service" "just test service" "16" "2" "$INSTDIR\srvany.exe" "" "" ""
	Pop $0 ; returns an errorcode (<>0) otherwise success (0)

	${If} $0 == 0
		DetailPrint "Install service success!"
	${Else}
		DetailPrint "Install service fail!"
	${EndIf}

	; 写注册表，添加参数，让 srvany.exe 运行我们自己的程序
	WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\test-service\Parameters" "Application" "$INSTDIR\index.exe"

	DetailPrint "Start service..."
	; Start a service. Be sure to pass the service name, not the display name.
	SimpleSC::StartService "test-service" "" 30

	# define uninstaller name
	WriteUninstaller $INSTDIR\uninstaller.exe
 
SectionEnd



# create a section to define what the uninstaller does.
# the section will always be named "Uninstall"
Section "Uninstall"

	# Always delete uninstaller first
	Delete $INSTDIR\uninstaller.exe

	# 由于 removeService时会直接删除注册表中该服务项所有信息，所以，不需要手动删除注册表
	# DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Services\test-service\Parameters"
	Call un.removeService
		
	# now delete installed file
	Delete $INSTDIR\index.exe
	Delete $INSTDIR\srvany.exe
	RMDir $INSTDIR
 
SectionEnd