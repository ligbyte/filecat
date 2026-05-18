@echo off
REM Check if the commit message is provided
if "%~1"=="" (
    echo Usage: commit.bat "Your commit message"
    exit /b 1
)

REM Store the commit message in a variable
set "commitMessage=%~1"

REM Add all changes
git add --all

REM Commit with the provided message
git commit -m "%commitMessage%"

REM Push changes to remote repository
git push

REM Notify user of completion
echo Commit and push completed.