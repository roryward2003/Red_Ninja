# PASTE LINK TO TEAM VIDEO BELOW
#
#

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global Main
  .global  SysTick_Handler
  .global EXTI0_IRQHandler

  @ Definitions are in definitions.s to keep this file "clean"
  .include "./src/definitions.s"

  .equ    BLINK_PERIOD, 500
  .equ    INCREMENT, 0x20004000
  .equ    INCREMENT_COUNTDOWN, 0x20004004
  .equ    CORRECT_COUNT, 0x20004008
  .equ    GAME_WON, 0x2000400C
  .equ    GAME_LOST, 0x20004010
  .equ    GAME_WON_2, 0x20004020
  .equ    GAME_LOST_2, 0x20004024

  .section .text

Main:
  PUSH  {R4-R12,LR}

  MOV     R12, #1
  LDR     R10, =INCREMENT
  STR     R12, [R10]

  MOV     R11, #5
  LDR     R10, =INCREMENT_COUNTDOWN
  STR     R11, [R10]

  MOV     R9, #0
  LDR     R10, =CORRECT_COUNT
  STR     R9, [R10]

  MOV     R8, #0
  LDR     R10, =GAME_WON
  STR     R8, [R10]

  MOV     R7, #0
  LDR     R10, =GAME_LOST
  STR     R7, [R10]

  MOV     R7, #0
  LDR     R10, =GAME_WON_2
  STR     R7, [R10]

  MOV     R7, #0
  LDR     R10, =GAME_LOST_2
  STR     R7, [R10]

  @
  @ Prepare GPIO Port E Pin 9 for output (LED LD3)
  @ We'll blink LED LD3 (the orange LED)
  @

  @ Enable GPIO port E by enabling its clock
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << (RCC_AHBENR_GPIOEEN_BIT))
  STR     R5, [R4]

  @ Configure LD3 for output
  @   by setting bits 27:26 of GPIOE_MODER to 01 (GPIO Port E Mode Register)
  @   (by BIClearing then ORRing)
  LDR     R4, =GPIOE_MODER
  LDR     R5, [R4]                  @ Read ...
  BIC     R5, #(0b11<<(LD3_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD3_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD4_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD4_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD5_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD5_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD6_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD6_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD7_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD7_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD8_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD8_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD9_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD9_PIN*2))  @ write 01 to bits 
  BIC     R5, #(0b11<<(LD10_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD10_PIN*2))  @ write 01 to bits 
  STR     R5, [R4]                  @ Write 

  @ Initialise the first countdown

  LDR     R4, =blink_countdown
  LDR     R5, =BLINK_PERIOD
  STR     R5, [R4]  

  @ Configure SysTick Timer to generate an interrupt every 1ms

  LDR     R4, =SCB_ICSR               @ Clear any pre-existing interrupts
  LDR     R5, =SCB_ICSR_PENDSTCLR     @
  STR     R5, [R4]                    @

  LDR     R4, =SYSTICK_CSR            @ Stop SysTick timer
  LDR     R5, =0                      @   by writing 0 to CSR
  STR     R5, [R4]                    @   CSR is the Control and Status Register
  
  LDR     R4, =SYSTICK_LOAD           @ Set SysTick LOAD for 1ms delay
  LDR     R5, =7999                   @ Assuming 8MHz clock
  STR     R5, [R4]                    @ 

  LDR     R4, =SYSTICK_VAL            @   Reset SysTick internal counter to 0
  LDR     R5, =0x1                    @     by writing any value
  STR     R5, [R4]

  LDR     R4, =SYSTICK_CSR            @   Start SysTick timer by setting CSR to 0x7
  LDR     R5, =0x7                    @     set CLKSOURCE (bit 2) to system clock (1)
  STR     R5, [R4]                    @     set TICKINT (bit 1) to 1 to enable interrupts
                                      @     set ENABLE (bit 0) to 1


  @
  @ Prepare external interrupt Line 0 (USER pushbutton)
  @ We'll count the number of times the button is pressed
  @

  @ Initialise count to zero
  LDR   R4, =button_count             @ count = 0;
  MOV   R5, #0                        @
  STR   R5, [R4]                      @

  @ Configure USER pushbutton (GPIO Port A Pin 0 on STM32F3 Discovery
  @   kit) to use the EXTI0 external interrupt signal
  @ Determined by bits 3..0 of the External Interrrupt Control
  @   Register (EXTIICR)
  LDR     R4, =SYSCFG_EXTIICR1
  LDR     R5, [R4]
  BIC     R5, R5, #0b1111
  STR     R5, [R4]

  @ Enable (unmask) interrupts on external interrupt Line0
  LDR     R4, =EXTI_IMR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Set falling edge detection on Line0
  LDR     R4, =EXTI_FTSR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Enable NVIC interrupt #6 (external interrupt Line0)
  LDR     R4, =NVIC_ISER
  MOV     R5, #(1<<6)
  STR     R5, [R4]

  @ Nothing else to do in Main
  @ Idle loop forever (welcome to interrupts!!)

  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  EOR     R5, #(0b1<<(LD3_PIN))
  STR     R5,[R4]
Idle_Loop:
  LDR     R6, =GAME_LOST
  LDR     R8, [R6]
  CMP     R8, #1
  BNE     .LgameNotOver      

  LDR     R4, =GPIOE_ODR
  MOV     R5, #0x0000FF00
  STR     R5, [R4]
  
  @   Stop SysTick timer by setting CSR to 0x0
  LDR     R4, =SYSTICK_CSR            @     set CLKSOURCE (bit 2) to system clock (0)
  LDR     R5, =0                      @     set TICKINT (bit 1) to 0 to disable interrupts
  STR     R5, [R4]                    @     set DISABLE (bit 0) to 0

  MOV     R8, #0
  LDR     R6, =GAME_LOST
  STR     R8, [R6]

  MOV     R8, #1
  LDR     R6, =GAME_LOST_2
  STR     R8, [R6]
  B       .LeIdleLoop
.LgameNotOver:
  LDR     R6, =GAME_WON
  LDR     R8, [R6]
  CMP     R8, #1
  BNE     .LeIdleLoop 

  LDR     R4, =GPIOE_ODR
  MOV     R5, #0x00000200
  STR     R5,[R4]

  LDR     R4, =blink_countdown
  LDR     R5, =100
  STR     R5, [R4]  

  MOV     R8, #0
  LDR     R6, =GAME_WON
  STR     R8, [R6]

  MOV     R8, #1
  LDR     R6, =GAME_WON_2
  STR     R8, [R6]
.LeIdleLoop:
  B     Idle_Loop

End_Main:
  POP   {R4-R12,PC}

@
@ SysTick interrupt handler (blink LED LD3)
@
  .type  SysTick_Handler, %function
SysTick_Handler:

  PUSH  {R4-R12, LR}

  LDR   R4, =blink_countdown              @ if (countdown != 0) {
  LDR   R5, [R4]                    @
  CMP   R5, #0                      @
  BEQ   .LelseFire                  @

  SUB   R5, R5, #1                  @   countdown = countdown - 1;
  STR   R5, [R4]                    @

  B     .LendIfDelay                @ }

.LelseFire:                         @ else {

  LDR     R7, =GAME_WON_2
  LDR     R6, [R7]
  CMP     R6, #1
  BEQ     .LgameWon

//.LgameNotYetWon:
  @ STM32F303 Reference Manual 11.4.6 (pg. 239)
  LDR     R4, =GPIOE_ODR            @   Invert LD3
  LDR     R5, [R4]    
  LDR     R10, =INCREMENT
  LDR     R9, =INCREMENT_COUNTDOWN
  LDR     R12, [R10]
  LDR     R11, [R9]
  
  CMP     R11, #0
  BGT     .LincrCountNotZero
  ADD     R12, R12, #1
  MOV     R11, #6
.LincrCountNotZero:
  CMP     R12, #5
  BLE     .LincrNotTooHigh
  @@ this is where it will speed up
  MOV     R12, #1
.LincrNotTooHigh:

  LSL     R5,R5,R12

  CMP     R5, #32768                 @ This part checks if the number has overflowed
  BLE     .LoverLaps                 @ If it has, it does LSR #8
  LSR     R5, R5, #8
.LoverLaps:

  SUB     R11, R11, #1

  STR     R5, [R4]                  @ 
  LDR     R10, =INCREMENT
  LDR     R9, =INCREMENT_COUNTDOWN
  STR     R12, [R10]
  STR     R11, [R9]

  LDR     R4, =blink_countdown            @   countdown = BLINK_PERIOD;
  LDR     R5, =BLINK_PERIOD         @
  STR     R5, [R4]                  @
  B       .LendIfDelay

.LgameWon:
  LDR     R4, =GPIOE_ODR            @   Invert LD3
  LDR     R5, [R4]

  LSL     R5, R5, #1
  CMP     R5, #32768
  BLE     .LeOverLapsWon
  MOV     R5, #256
.LeOverLapsWon:
  STR     R5, [R4]

  LDR     R4, =blink_countdown            @   countdown = BLINK_PERIOD;
  LDR     R5, =100                  @
  STR     R5, [R4]                  @

.LendIfDelay:                       @ }

  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR     R4, =SCB_ICSR             @ Clear (acknowledge) the interrupt
  LDR     R5, =SCB_ICSR_PENDSTCLR   @
  STR     R5, [R4]                  @

  @ Return from interrupt handler
  POP  {R4-R12, PC}


@
@ External interrupt line 0 interrupt handler
@   (count button presses)
@
  .type  EXTI0_IRQHandler, %function
EXTI0_IRQHandler:

  PUSH  {R4,R5,LR}

  LDR     R7, =GAME_WON_2
  LDR     R6, [R7]
  CMP     R6, #1
  BEQ     .LeHandler
  LDR     R7, =GAME_LOST_2
  LDR     R6, [R7]
  CMP     R6, #1
  BEQ     .LeHandler

  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]

  CMP     R5, #0x00000800
  BEQ     .LlightRed
  CMP     R5, #0x00008000
  BEQ     .LlightRed
  B       .LlightNotRed
.LlightRed:
  LDR     R10, =CORRECT_COUNT
  LDR     R9, [R10]
  ADD     R9, R9, #1
  STR     R9, [R10]

  CMP     R9, #5
  BLT     .LeLightRed
  MOV     R8, #1
  LDR     R10, =GAME_WON
  STR     R8, [R10]    
  // Check if won, and if so set a gameWon boolean to true

  B       .LeLightRed
.LlightNotRed:
  MOV     R7, #1
  LDR     R10, =GAME_LOST
  STR     R7, [R10]
  // Game lost, set a gameLost boolean to true

.LeLightRed:
  LDR   R4, =EXTI_PR                @ Clear (acknowledge) the interrupt
  MOV   R5, #(1<<0)                 @
  STR   R5, [R4]                    @

.LeHandler:
  @ Return from interrupt handler
  POP  {R4,R5,PC}


  .section .data
  
button_count:
  .space  4

blink_countdown:
  .space  4

  .end