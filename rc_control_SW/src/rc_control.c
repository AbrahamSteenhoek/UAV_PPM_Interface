/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */


#include "rc_control.h"

int main()
{
    init_platform();

    print("PPM Capture Test\n\r");

    if ( VerifyDeviceIDs() == -1 )
    	return -1;

    while( !exit_condition )
    {
        ReadInputs();

        GPIOPrint();

        PPMInputModeHandler();
		
		FilterModeHandler();
		
        RelayModeHandler();

    	SoftwareDebugModeHandler();
        
        SoftwareRecordModeHandler();

        SoftwarePlayModeHandler();
    }

    xil_printf( "Exiting application...\r\n");
    cleanup_platform();
    return 0;
}

int VerifyDeviceIDs()
{
    // device ID for AXI_PPM device in slv_reg3
    if ( AXI_PPM[3] != AXI_PPM_DEVICE_ID )
    {
    	xil_printf( "Error detecting AXI PPM Interface Device. Exiting...\r\n" );
    	return -1;
    }

    // device ID for GPIO_DEVICE in slv_reg15
    if ( GPIO_DEVICE[15] != GPIO_DEVICE_ID )
    {
		xil_printf( "Error detecting GPIO Device . Exiting...\r\n" );
		return -1;
	}

    return 0;
}

void GPIOPrint()
{
    if ( GPIO_PRINT_MODE == GPIO_PRINT_ON )
        xil_printf( "BTNS: 0x%02x | SWS: 0x%02x\r\n", GPIO_DEVICE[BTN_OFST], GPIO_DEVICE[SW_OFST] );
}

/*
    Reads the inputs of the buttons and switches, and sets the AXI_PPM operating modes accordingly
*/
void ReadInputs()
{
    u8 sw_state = GPIO_DEVICE[SW_OFST];
    u8 btn_state = GPIO_DEVICE[BTN_OFST];

    // press center button to exit application
    exit_condition = ( btn_state & BTN_CENTER ) ? true : false;

    GPIO_PRINT_MODE = ( sw_state & SW[7] ) ? GPIO_PRINT_ON : GPIO_PRINT_OFF;

    prev_btn_UP_state = btn_UP_state;
    btn_UP_state = ( btn_state & BTN_UP ) ? PRESSED : OPEN; // need debounce? probably not
    prev_btn_DOWN_state = btn_DOWN_state;
    btn_DOWN_state = ( btn_state & BTN_DOWN ) ? PRESSED : OPEN; // need debounce? probably not
    prev_btn_LEFT_state = btn_LEFT_state;
    btn_LEFT_state = ( btn_state & BTN_LEFT ) ? PRESSED : OPEN; // need debounce? probably not
    prev_btn_RIGHT_state = btn_RIGHT_state;
    btn_RIGHT_state = ( btn_state & BTN_RIGHT ) ? PRESSED : OPEN; // need debounce? probably not

    // switch 5 determines whether AXI_PPM module takes input from
    // the RC transmitter (SW5 = OFF)
    // or
    // the PPM signal controlled by the virtual interface (SW5 = ON)
    PPM_INPUT_MODE = ( sw_state & SW[5] ) ? VIRTUAL_CONTROL_INPUT : RC_INPUT;

    RELAY_MODE = ( sw_state & SW[0] ) ? SW_RELAY : HW_RELAY;

    SW_DEBUG_MODE = ( sw_state & SW[1] ) ? SW_DEBUG_ON : SW_DEBUG_OFF;

    SW_RECORD_MODE = ( sw_state & SW[2] ) ? SW_RECORD_ON : SW_RECORD_OFF;
    SW_RECORD_RESET = (bool)( sw_state & SW[6] ); 
 
    SW_PLAY_MODE = ( sw_state & SW[3] ) ? SW_PLAY_ON : SW_PLAY_OFF;

    FILTER_MODE = ( sw_state & SW[4] ) ? FILTER_ON : FILTER_OFF;
}

void PPMInputModeHandler()
{
    AXI_PPM[ PPM_INPUT_SOURCE ] = ( PPM_INPUT_MODE == RC_INPUT ) ? 0x0 : 0x1;
}

void RelayModeHandler()
{
    if ( RELAY_MODE == SW_RELAY ) // software_relay
    {
        if ( FILTER_MODE == FILTER_ON )
        {
        }
        else
        {
            AXI_PPM[CH0_GEN] = AXI_PPM[CH0];
            AXI_PPM[CH1_GEN] = AXI_PPM[CH1];
            AXI_PPM[CH2_GEN] = AXI_PPM[CH2];
            AXI_PPM[CH3_GEN] = AXI_PPM[CH3];
            AXI_PPM[CH4_GEN] = AXI_PPM[CH4];
            AXI_PPM[CH5_GEN] = AXI_PPM[CH5];

            // set slv_reg0 to 1 to put hardware in "software relay mode"
            AXI_PPM[0] = 0x1;
        }
    }
    else // HW_RELAY
    {
        // set slv_reg0 to 0 to put hardware in "hardware relay mode"
    	AXI_PPM[0] = 0x0;
    }

}

int CountToPercent( int cycle_count )
{
    int percent_val = 0;
    int cycle_count_minus_pulse = cycle_count - 40000;
    if ( cycle_count_minus_pulse > 100000 )
    {
        percent_val = cycle_count_minus_pulse - 100000;
        percent_val /= 1000;
    }
    else
    {
        percent_val = ( cycle_count_minus_pulse - 50000 ) * 2;
        percent_val /= 1000;
        percent_val = 100 - percent_val;
        percent_val *= -1;
    }
    if ( ( percent_val > 100 ) || ( percent_val < -100 ) )
        percent_val = 0;
    return percent_val;
}

// ch0 - roll
// ch1 - pitch
// ch2 - throttle
// ch3 - yaw
void SoftwareDebugModeHandler()
{
    // TODO: maybe print % of throttle, roll, pitch, yaw to the screen instead of channel values? (need to know min and max for this)
    // also, ch5/6 aren't needed, so maybe that's not needed
    if ( SW_DEBUG_MODE == SW_DEBUG_ON ) // software_relay
    {
        const u8 FRAME_COUNT_OFST = 1;

        // xil_printf( "CH0: %05x CH1: %05x CH2: %05x CH3: %05x CH4: %05x CH5: %05x, slv_reg1: %08x\r\n",
        //     AXI_PPM[CH0],
        //     AXI_PPM[CH1],
        //     AXI_PPM[CH2],
        //     AXI_PPM[CH3],
        //     AXI_PPM[CH4],
        //     AXI_PPM[CH5],
        //     AXI_PPM[FRAME_COUNT_OFST]
        // );
        xil_printf( "Roll: %02d%% | Pitch: %02d%% | Throttle: %02d%% | Yaw: %02d%% | Frame Count: %12u\r\n",
            CountToPercent( AXI_PPM[CH0] ),
            CountToPercent( AXI_PPM[CH1] ),
            CountToPercent( AXI_PPM[CH2] ),
            CountToPercent( AXI_PPM[CH3] ),
            AXI_PPM[FRAME_COUNT_OFST]
        );
    }
}

void ResetRecording()
{
    xil_printf( "Resetting frame recording...\r\n" );
    frame_record_index = 0;
    for ( int i = 0; i < MAX_FRAMES; i++ )
        for ( int j = 0; j < NUM_CHANNELS; j++ )
            frame_record[i][j] = 0;
    frame_replay_index = 0; // frame record has changed, reset replay index
}

void SoftwareRecordModeHandler()
{
    if ( SW_RECORD_RESET )
    {
        ResetRecording();
    }
    if ( SW_RECORD_MODE == SW_RECORD_ON )
    {
        // xil_printf("recording mode ON\r\n");
        if ( ( btn_DOWN_state == PRESSED ) && ( prev_btn_DOWN_state == OPEN ) )
        {
            frame_record[ frame_record_index ][ 0 ] = AXI_PPM[ CH0 ];
            frame_record[ frame_record_index ][ 1 ] = AXI_PPM[ CH1 ];
            frame_record[ frame_record_index ][ 2 ] = AXI_PPM[ CH2 ];
            frame_record[ frame_record_index ][ 3 ] = AXI_PPM[ CH3 ];
            frame_record[ frame_record_index ][ 4 ] = AXI_PPM[ CH4 ];
            frame_record[ frame_record_index ][ 5 ] = AXI_PPM[ CH5 ];

            if ( frame_record_index + 1 < MAX_FRAMES )
            {
                xil_printf( "Recorded the following frame at index: %d\r\nCH0: %5x CH1: %5x CH2: %5x CH3: %5x CH4: %5x CH5: %5x\r\n",
                    frame_record_index,
                    frame_record[ frame_record_index ][ 0 ],
                    frame_record[ frame_record_index ][ 1 ],
                    frame_record[ frame_record_index ][ 2 ],
                    frame_record[ frame_record_index ][ 3 ],
                    frame_record[ frame_record_index ][ 4 ],
                    frame_record[ frame_record_index ][ 5 ]
                );

                frame_record_index++;
                frame_replay_index = 0; // frame record has changed, reset replay index
            }
            else
            {
                xil_printf( "Recorded maximum possible frames. Press SW6 to reset\r\n" );
            }
        }
        else if ( ( btn_UP_state == PRESSED ) && ( prev_btn_UP_state == OPEN ) )
        {
            for ( int i = 0; i < NUM_CHANNELS; i++ )
                frame_record[ frame_record_index ][ i ] = 0; // delete the record at the current index
            
            if ( frame_record_index - 1 >= 0 )
            {
                xil_printf( "Rewinding frame at index: %d\r\n", frame_record_index );
                frame_record_index--;
                frame_replay_index = 0; // frame record has changed, reset replay index
            }
            else
            {
                xil_printf( "No frames left in recording.\r\n" );
            }
        }
    }
}

void SoftwarePlayModeHandler()
{
    // xil_printf("recording mode ON\r\n");
    if ( SW_PLAY_MODE == SW_PLAY_ON )
    {
        if ( ( btn_RIGHT_state == PRESSED ) && ( prev_btn_RIGHT_state == OPEN ) )
        {
            if ( frame_replay_index + 1 < MAX_FRAMES )
            {
                // NOTE: SW replay mode does not support SW filtering
                if ( frame_record[frame_replay_index][0] != 0x0 ) // no need to replay empty frames
                {
                    AXI_PPM[ CH0_GEN ] = frame_record[ frame_replay_index ][ 0 ];
                    AXI_PPM[ CH1_GEN ] = frame_record[ frame_replay_index ][ 1 ];
                    AXI_PPM[ CH2_GEN ] = frame_record[ frame_replay_index ][ 2 ];
                    AXI_PPM[ CH3_GEN ] = frame_record[ frame_replay_index ][ 3 ];
                    AXI_PPM[ CH4_GEN ] = frame_record[ frame_replay_index ][ 4 ];
                    AXI_PPM[ CH5_GEN ] = frame_record[ frame_replay_index ][ 5 ];

                    xil_printf( "Replaying the frame recorded at index: %d\r\nCH0: %5x CH1: %5x CH2: %5x CH3: %5x CH4: %5x CH5: %5x\r\n",
                        frame_replay_index,
                        frame_record[ frame_replay_index ][ 0 ],
                        frame_record[ frame_replay_index ][ 1 ],
                        frame_record[ frame_replay_index ][ 2 ],
                        frame_record[ frame_replay_index ][ 3 ],
                        frame_record[ frame_replay_index ][ 4 ],
                        frame_record[ frame_replay_index ][ 5 ]
                    );
                }
                else
                {
                    xil_printf( "Skipping empty frame at index %d. Moving to next index\r\n", frame_replay_index );
                }
                frame_replay_index++;
            }

        }
        else if ( ( btn_LEFT_state == PRESSED ) && ( prev_btn_LEFT_state == OPEN ) )
        {
            if ( frame_replay_index - 1 >= 0 )
            {
                xil_printf( "Rewinding replay to index: %d\r\n", frame_replay_index - 1 );
                frame_replay_index--;
            }
            else
            {
                xil_printf( "Replay index is already at 0\r\n" );
            }
        }
    }
}

void FilterModeHandler()
{
    if ( FILTER_MODE == FILTER_ON )
    {
        if( AXI_PPM[CH0] > 200000)
        {
            AXI_PPM[CH0_GEN] = 200000;
        }
        if( AXI_PPM[CH0] < 110000 )
        {
            AXI_PPM[CH0_GEN] = 110000;
        }
        if( AXI_PPM[CH1] > 200000)
        {
            AXI_PPM[CH1_GEN] = 200000;
        }
        if( AXI_PPM[CH1] < 110000 )
        {
            AXI_PPM[CH1_GEN] = 110000;
        }
        if( AXI_PPM[CH2] > 200000)
        {
            AXI_PPM[CH2_GEN] = 200000;
        }
        if( AXI_PPM[CH2] < 110000 )
        {
            AXI_PPM[CH2_GEN] = 110000;
        }
        if( AXI_PPM[CH3] > 200000)
        {
            AXI_PPM[CH3_GEN] = 200000;
        }
        if( AXI_PPM[CH3] < 110000 )
        {
            AXI_PPM[CH3_GEN] = 110000;
        }
        if( AXI_PPM[CH4] > 200000)
        {
            AXI_PPM[CH4_GEN] = 200000;
        }
        if( AXI_PPM[CH4] < 110000 )
        {
            AXI_PPM[CH4_GEN] = 110000;
        }
        if( AXI_PPM[CH5] > 200000)
        {
            AXI_PPM[CH5_GEN] = 200000;
        }
        if( AXI_PPM[CH5] < 110000 )
        {
            AXI_PPM[CH5_GEN] = 110000;
        }
    }
}
