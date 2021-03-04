#include <stdio.h>
#include <ctype.h>
#include <stdbool.h>

#include "platform.h"
#include "xparameters.h"
#include "sleep.h"

#define AXI_PPM_DEVICE_ID 0x44335566 
#define GPIO_DEVICE_ID 0xFEDC4321 

#define PPM_INPUT_SOURCE 17
#define BTN_CENTER 0x1
#define BTN_UP 0x10
#define BTN_DOWN 0x2
#define BTN_RIGHT 0x4
#define BTN_LEFT 0x8

#define RELAY_MODE_OFST 0

u32* AXI_PPM = (u32*) XPAR_AXI_PPM_32R_0_S00_AXI_BASEADDR;

#define CH0 10
#define CH1 11
#define CH2 12
#define CH3 13
#define CH4 14
#define CH5 15

#define CH0_GEN 20
#define CH1_GEN 21
#define CH2_GEN 22
#define CH3_GEN 23
#define CH4_GEN 24
#define CH5_GEN 25

u32* GPIO_DEVICE = (u32*)XPAR_LED_SETTER_0_S00_AXI_BASEADDR;
#define BTN_OFST 0
#define SW_OFST 1

const u8 SW[8] = {1, 2, 4, 8, 16, 32, 64, 128};

enum GPIOPrintType { GPIO_PRINT_ON, GPIO_PRINT_OFF };
enum GPIOPrintType GPIO_PRINT_MODE = GPIO_PRINT_OFF;

enum PPMInputType { RC_INPUT, VIRTUAL_CONTROL_INPUT };
enum PPMInputType PPM_INPUT_MODE = RC_INPUT;

enum RelayType { HW_RELAY, SW_RELAY };
enum RelayType RELAY_MODE = SW_RELAY;

enum SWDebugType { SW_DEBUG_ON, SW_DEBUG_OFF };
enum SWDebugType SW_DEBUG_MODE = SW_DEBUG_OFF;

enum SWRecordType { SW_RECORD_ON, SW_RECORD_OFF };
enum SWRecordType SW_RECORD_MODE = SW_RECORD_OFF;
bool SW_RECORD_RESET = false;

enum SWPlayType { SW_PLAY_ON, SW_PLAY_OFF };
enum SWPlayType SW_PLAY_MODE = SW_PLAY_OFF;

enum FilterType { FILTER_ON, FILTER_OFF };
enum FilterType FILTER_MODE = FILTER_OFF;

bool exit_condition = false;

enum ButtonState { PRESSED, OPEN };
enum ButtonState btn_UP_state = OPEN;
enum ButtonState prev_btn_UP_state = OPEN;
enum ButtonState btn_DOWN_state = OPEN;
enum ButtonState prev_btn_DOWN_state = OPEN;
enum ButtonState btn_LEFT_state = OPEN;
enum ButtonState prev_btn_LEFT_state = OPEN;
enum ButtonState btn_RIGHT_state = OPEN;
enum ButtonState prev_btn_RIGHT_state = OPEN;

#define MAX_FRAMES 69
#define NUM_CHANNELS 6
u32 frame_record[ MAX_FRAMES ][ NUM_CHANNELS ];
int frame_record_index = 0;

int frame_replay_index = 0;

void GPIOPrint();
int VerifyDeviceIDs();
void ReadInputs();
void PPMInputModeHandler();
void RelayModeHandler();
int CountToPercent( int cycle_count );
void SoftwareDebugModeHandler();
void ResetRecording();
void SoftwareRecordModeHandler();
void SoftwarePlayModeHandler();
void FilterModeHandler();

