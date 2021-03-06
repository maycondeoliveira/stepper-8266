--
-- Created by IntelliJ IDEA.
-- User: uday
-- Date: 26/11/16
-- Time: 10:47 PM
-- Interfaces ULN2003 for driving a 28BYJ-48 stpper motor
-- First needs to be intialized with pin connection data and interval at which the motor should run
pin = 6
gpio.mode(pin,gpio.INPUT)
local stepper = {}
do
    ---------------------------------------------------------------------------------------
    -- constants
    ---------------------------------------------------------------------------------------

    -- To control the stepper, apply voltage to each of the coils in a specific sequence.
    -- refer to below link for sepcific sequence
    -- https://www.geeetech.com/wiki/index.php/Stepper_Motor_5V_4-Phase_5-Wire_%26_ULN2003_Driver_Board_for_Arduino
    local PHASE_GPIO_DATA = {
        { gpio.LOW,  gpio.LOW,  gpio.LOW,   gpio.HIGH },
        { gpio.LOW,  gpio.LOW,  gpio.HIGH,  gpio.HIGH },
        { gpio.LOW,  gpio.LOW,  gpio.HIGH,  gpio.LOW },
        { gpio.LOW,  gpio.HIGH, gpio.HIGH,  gpio.LOW },
        { gpio.LOW,  gpio.HIGH, gpio.LOW,   gpio.LOW },
        { gpio.HIGH, gpio.HIGH, gpio.LOW,   gpio.LOW },
        { gpio.HIGH, gpio.LOW,  gpio.LOW,   gpio.LOW },
        { gpio.HIGH, gpio.LOW,  gpio.LOW,   gpio.HIGH }
    }

    local PHASE_LOWER_BOUND = 1;
    local PHASE_UPPER_BOUND = 8;

    local FORWARD = 1;
    local REVERSE = -1;
    local REPEATING_TIMER = 1;

    ---------------------------------------------------------------------------------------
    -- motor configuration data
    ---------------------------------------------------------------------------------------
    local motor_params = {}

    -- nodemcu pin numbers on which to motor is connected
    motor_params.pins = {2,4}
        -- NODEMCU ------- ULN2003
        -- D5 ( GPIO14 ) <-> IN1
        -- D6 ( GPIO12 ) <-> IN2
        -- D7 ( GPIO13 ) <-> IN3
        -- D8 ( GPIO15 ) <-> IN4
    motor_params.step_interval = 5 -- milliseconds decides the speed. smaller the interval, higher the speed.
    motor_params.desired_steps = 2500
    motor_params.direction = FORWARD
    motor_params.timer_to_use = 0
    motor_params.callback = nil


    ---------------------------------------------------------------------------------------
    -- rotation state data
    ---------------------------------------------------------------------------------------

    local step_counter  = 0     --total number of steps done since the call started
    local phase         = 1     --which stepper phase are we in ? can be 1 to 8. intialize with 1


    ---------------------------------------------------------------------------------------
    -- Private ( Auxillary and Utility ) methods
    ---------------------------------------------------------------------------------------

    -- utility method do calculate modulo. has same effect as a%b in java,c,c++
    local mod = function (a,b)
        return a - math.floor(a/b)*b
    end

    local SleepMotor = function ()
        gpio.write(motor_params.pins[1] , gpio.LOW)
        print(motor_params.pins[1],gpio.read(motor_params.pins[1]))
        gpio.write(motor_params.pins[2] , gpio.LOW)
        print(motor_params.pins[2],gpio.read(motor_params.pins[2]))
    end
    
    local updatePhaseForNextStep = function ()
        --increment phase in given direction
        dir = motor_params.direction
        -- wrap phase around to keep it in bounds
        if dir == 1 then
            gpio.write(motor_params.pins[2],gpio.HIGH)
            print('dir',dir)
        elseif dir == -1 then
            gpio.write(motor_params.pins[2],gpio.LOW)
            print('dir',dir)
        end
    end

    -- one step in given direction
    local single_step = function ()
        --increment the counter and check if there are steps to execute
        step_counter = step_counter + 1
        if step_counter > motor_params.desired_steps or gpio.read(pin)==1 then
            tmr.stop(motor_params.timer_to_use)
            SleepMotor()
            node.task.post(2, motor_params.callback) -- node.task.HIGH_PRIORITY = 2
            print(gpio.read(pin))
        else
            updatePhaseForNextStep();
                gpio.write(motor_params.pins[1],gpio.HIGH)
                tmr.delay(50000); 
                print('a',gpio.read(motor_params.pins[1]))
                gpio.write(motor_params.pins[1],gpio.LOW)
                tmr.delay(50000);
                print('b',gpio.read(motor_params.pins[1]))
                print(gpio.read(motor_params.pins[2]))
        end
    end

    ---------------------------------------------------------------------
    -- moule public methods

    -- initializes motor
    -- expects a table with 4 gpio pins on which uln2003 is connected
    -- for exmaple, {5,6,7,8} is expected if uln2003 motor driver is connected in below scheme
        -- NODEMCU --- ULN2003
        -- D5 < ------ > IN1
        -- D6 < ------ > IN2
        -- D7 < ------ > IN3
        -- D8 < ------ > IN4
    local init = function ( pins )
        if not pins or not interval then
            print('Init params missing !!! initializing with defaults')
            local motor_pins = motor_params.pins;
            for i,pin in ipairs( motor_pins ) do
                gpio.mode(pin, gpio.OUTPUT)
            end
        else
            for i,pin in ipairs(pins) do
                gpio.mode(pin, gpio.OUTPUT)
                print(pin, 'gpio.OUTPUT')
                motor_params.pins[i]=pin;
            end
        end
        step_counter  = 0
        phase         = 1
    end

    -- rotates motor in a given direction. takes a callback to call once the rotation is done
    -- params
        -- direction = stepper.FORWARD or stepper.REVERSE
        -- desired_steps = number between 0 to infinity - 2500 is default
        -- interval = time delay in milliseconds between steps, smaller self number is, faster the motor rotates . 5 is default
    local rotate = function ( direction, desired_steps, interval, timer_to_use, callback)
        motor_params.step_interval = interval -- milliseconds decides the speed. smaller the interval, higher the speed.
        motor_params.desired_steps = desired_steps
        motor_params.direction = direction
        motor_params.timer_to_use = timer_to_use
        motor_params.callback = callback
        
        step_counter  = 0
        phase         = 1
        
        tmr.alarm(motor_params.timer_to_use, motor_params.step_interval, REPEATING_TIMER, single_step)
    end

    stepper = {
        FORWARD = FORWARD,
        REVERSE = REVERSE,
        init = init,
        rotate = rotate,
    }
end
return stepper
