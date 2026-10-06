#pragma once

#define FENGYU_CODE_NAME "Fengyu"
// Fengyu IME uses its own names for everything shared system-wide, so it can
// coexist with other input methods.
#define FENGYU_REG_KEY L"Software\\Fengyu\\IME"
#define FENGYU_REG_KEY_WOW64 L"Software\\WOW6432Node\\Fengyu\\IME"
#define FENGYU_UPDATES_REG_KEY FENGYU_REG_KEY L"\\Updates"
#define FENGYU_ROOT_REG_KEY L"Software\\Fengyu"
// default user data dir and log dir
#define FENGYU_DEFAULT_USER_DIR L"%AppData%\\Fengyu"
#define FENGYU_LOG_DIR L"%TEMP%\\fengyu-ime"
// named kernel objects
#define FENGYU_DEPLOYER_MUTEX L"FengyuDeployerMutex"
#define FENGYU_DEPLOYER_EXCLUSIVE_MUTEX L"FengyuDeployerExclusiveMutex"

#define STRINGIZE(x) #x
#define VERSION_STR(x) STRINGIZE(x)
#define FENGYU_VERSION VERSION_STR(VERSION_MAJOR.VERSION_MINOR.VERSION_PATCH)
