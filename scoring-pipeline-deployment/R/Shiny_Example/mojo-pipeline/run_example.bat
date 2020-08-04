@echo off
set MOJO_FILE=%1
set CSV_FILE=%2
set LICENSE=%3
IF "%MOJO_FILE%"=="" (
	set MOJO_FILE="pipeline.mojo"
)
if "%CSV_FILE%"=="" (
	set CSV_FILE="example.csv"
)

set COMMAND=java -Dai.h2o.mojos.runtime.license.file=%LICENSE% -cp mojo2-runtime.jar ai.h2o.mojos.executeMojo

for %%I in (
	"======================"
	"Running MOJO2 example"
	"======================"
	""
	"MOJO file    : %MOJO_FILE%"
	"Input file   : %CSV_FILE%"
	""
	"Command line : %COMMAND%"
) do echo %%~I

%COMMAND% %MOJO_FILE% %CSV_FILE%
pause
