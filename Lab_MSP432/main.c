#include "msp.h"

// Manipulation 1
void bad_PWM(int period, int on_time){

    // Pin setup
    P3DIR = 0x4; // Make port 3.2 an output
    P3OUT = 0x0; // Ensure defined value

    // Predefining integer for iteration
    int i;

    // Main Loop
    while(1){
        // Turn pin on
        P3OUT = 0x4;
        // Wait
        for(i = 0; i < on_time; i++);
        // Turn pin off
        P3OUT = 0x0;
        // Wait
        for(i = 0; i < (period - on_time); i++);
    }
}

// Manipulation 2
void chenillard(void){

    // Pin setup
    P4DIR = 0xFF; // Make the whole port 4 an output
    P4OUT = 0x00; // Make all zeroes

    // Predefining integer for iteration
    int i;

    while(1){
        // Rotate
        int8_t temp = P4OUT;

        temp <<= 1;
        if (temp == 0x0)    temp = 0x1;

        P4OUT = temp;

        // Wait(optional)
        for(i = 0; i < 100; i++);
    }
}

// Support for timer
void timer_delay_ms_init(void){
    // Choose 32kHz timer for its range (up to 2s)
    // And acceptable resolution (0.03ms)
    // The input clock (and divider) could be better chosen if given more info
    TA0CTL = TIMER_A_CTL_SSEL__ACLK;
}

// Manipulation 3
void timer_delay_ms(int delay){

    // Load wait time into register
    TA0CCR0 = (uint16_t) (delay*32.687); // FP unit needed?

    // Start counting in up mode
    TA0CTL |= MC__UP;

    // Poll end of counting
    while(!(TA0CCTL0 & CCIFG)){};

    // Clear Flag
    TA0CCTL0 &= ~CCIFG;

    // Stop counting
    TA0CTL &= ~MC_M;

    // Reset counter to 0
    TA0R = 0x00;
}

void timer_delay_test(int delay){

    timer_delay_ms_init();
    // Pin setup
        P3DIR = 0x4; // Make port 3.2 an output
        P3OUT = 0x0; // Ensure defined value

        // Main Loop
        while(1){
            // Turn pin on
            P3OUT = 0x4;
            // Wait
            timer_delay_ms(delay);
            // Turn pin off
            P3OUT = 0x0;
            // Wait
           timer_delay_ms(delay);
        }
}

// Manipulation 4
void timer_PWM(int period, int on_time){

    timer_delay_ms_init();
    // Pin setup
        P3DIR = 0x4; // Make port 3.2 an output
        P3OUT = 0x0; // Ensure defined value

        // Main Loop
        while(1){
            // Turn pin on
            P3OUT = 0x4;
            // Wait
            timer_delay_ms(on_time);
            // Turn pin off
            P3OUT = 0x0;
            // Wait
           timer_delay_ms(period - on_time);
        }
}

// Support for interrupt
void TA0_0_IRQHandler(void){
    TA0CCTL0 &= ~CCIFG;
    P3OUT ^= 0x4;
}

// Manipulation 5
void timer_interrupt_start(int delay){

    // Pin Setup
    P3DIR = 0x4; // Make port 3.2 an output
    P3OUT = 0x0; // Ensure defined value

    // Choose 32kHz timer for its range (up to 2s)
    // And acceptable resolution (0.03ms)
    TA0CTL = TIMER_A_CTL_SSEL__ACLK | TAIE;

    TA0CCTL0 |= CCIE;

    // Load wait time into register
    TA0CCR0 = (uint16_t) (delay*32.687); // FP unit needed?

    NVIC_EnableIRQ(TA0_0_IRQn);

    // Start counting in up mode
    TA0CTL |= MC__UP;
}

// Manipulation 6
void ADC_read_init(void){
        //GPIO
        P4SEL0 = 1; // Activate secondary module

        NVIC_EnableIRQ(ADC14_IRQn);   // Enable ADC interrupt in NVIC module

        // Configure ADC14
        ADC14->CTL0 = ADC14_CTL0_SHT0_2 | ADC14_CTL0_ON | ADC14_CTL0_SHS_2 | ADC14_CTL0_CONSEQ_2;
        ADC14->CTL1 = ADC14_CTL1_RES__12BIT;                   // Use sampling timer, 12-bit conversion results

        ADC14->MCTL[0] = ADC14_MCTLN_INCH_13;                // A13 ADC input select; Vref=AVCC

        ADC14->IER0 |= ADC14_IER0_IE0;                    // Enable ADC conv complete interrupt
        ADC14->CTL0 |= ADC14_CTL0_ENC;
}

void PWM_duty_cycle(int percent){
    TA0CCR1 = (uint16_t) (50*percent*32.687/100);
}

// ADC14 interrupt service routine
void ADC14_IRQHandler(void) {
    TA0CCR1 = (uint16_t) (1*32.687+32.687*ADC14->MEM[0]/(1<<12));
    //__sleep();

}

void PWM_init(void){
     // Choose 32kHz timer for its range (up to 2s)
     // And acceptable resolution (0.03ms)
     // The input clock (and divider) could be better chosen
     TA0CTL = TIMER_A_CTL_SSEL__ACLK;

     // Start continuous
     TA0CTL |= MC__UP;

     // Set up period
     TA0CCR0 = (uint16_t) (20 * 32.687);

     // Set up PWM output
     TA0CCTL1 |= OUTMOD_7;

     // Set up default PWM output (0 chosen for safety)
     TA0CCR1 = 0;

     // Default outputs to P2.4?
    P2->DIR = 0xFF;
    P2->SEL0 = 1 << 4;
    P2->SEL1 = 0;

    // Intervals for ADC
    TA0CCR2 = 1;
    TA0CCTL2 |= OUTMOD_7;
}


/**
 * main.c
 */
void main(void)
{
	WDT_A->CTL = WDT_A_CTL_PW | WDT_A_CTL_HOLD;		// stop watchdog timer

	// Manipulation 1
	//bad_PWM(100, 20);

	// Manipulation 2
	//chenillard();

	// Manipulation 3
	//timer_delay_test(10);

	// Manipulation 4
	//timer_PWM(100, 20);

	// Manipulation 5
	//timer_interrupt_start(10);

	// Manipulation 6



	// Manipulation 7
	PWM_init();
    ADC_read_init();
    while(1){

    }
}
