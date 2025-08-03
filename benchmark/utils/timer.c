#include "timer.h"
long time() {
    return (long) TIMER_COUNTER_REG;
}