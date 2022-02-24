#include "msp.h"
#define CLK_TIMER 32687

void GPIO_init(void){
    
    // ADC input A13 enabled
    P4->SEL0 = 1 << 0;

    // Set port 2 to output. Use port 2.4 for PWM output of Timer TA0.1
    P2->DIR = 0xFF;
    P2->SEL0 = 1 << 4;   // Set to secondary function
    P2->SEL1 = 0;           
}

void ADC_read_init(void){
        NVIC_EnableIRQ(ADC14_IRQn);

        // Configure ADC14 parameters
        ADC14->CTL0 = ADC14_CTL0_SHT0_2 | ADC14_CTL0_ON | ADC14_CTL0_SHS_2 | ADC14_CTL0_CONSEQ_2;
        
        // Set 12 bit resolution
        ADC14->CTL1 = ADC14_CTL1_RES__12BIT;

        // A13 ADC input select
        ADC14->MCTL[0] = ADC14_MCTLN_INCH_13;

        // Enable ADC conversion complete interrupt
        ADC14->IER0 |= ADC14_IER0_IE0;

        // Enable (and "start") conversions
        ADC14->CTL0 |= ADC14_CTL0_ENC;
}

void timerA0_init(void){
     
     // Choose 32kHz timer for its range (up to 2s)
     // And acceptable resolution (0.03ms)
     // The input clock (and divider) could be better chosen
     TA0CTL = TIMER_A_CTL_SSEL__ACLK;

     // Set up Up mode of operation
     TA0CTL |= MC__UP;

     // Set the period to 20 ms
     TA0CCR0 = (uint16_t) (20 * CLK_TIMER/1000);

     // Set up output mode 7 for PWM
     TA0CCTL1 |= OUTMOD_7;

     // Set up default PWM output (0 chosen for safety)
     TA0CCR1 = 0;

    // Periodic intervals for ADC, output mode 7
    TA0CCTL2 |= OUTMOD_7;
    // Set up to arbitrary value
    TA0CCR2 = 1;
}

// ADC14 interrupt service routine
void ADC14_IRQHandler(void) {
    TA0CCR1 = (uint16_t) (CLK_TIMER/1000+CLK_TIMER/1000*ADC14->MEM[0]/(1<<12));
}

void main(void)
{
    WDT_A->CTL = WDT_A_CTL_PW | WDT_A_CTL_HOLD;     // stop watchdog timer

    GPIO_init();

    timerA0_init();
    ADC_read_init();

    while(1){}
}
