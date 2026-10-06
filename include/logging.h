#ifndef FENGYU_LOGGGING_H_
#define FENGYU_LOGGGING_H_

#ifdef FENGYU_ENABLE_LOGGING
#define GLOG_NO_ABBREVIATED_SEVERITIES
#pragma warning(disable : 4244)
#include <glog/logging.h>
#pragma warning(default : 4244)
#else
#include "no_logging.h"
#endif  // FENGYU_ENABLE_LOGGING

#endif  // FENGYU_LOGGGING_H_
