stepper  = require ('stepper')
pins = {4,1}
stepper.init(pins)
desired_steps = 10
interval = 10
timer_to_use = 0
tmr.delay(500)
print('stepper.rotate() - start')
stepper.rotate(stepper.FORWARD,desired_steps,interval,timer_to_use,function ()
    print('Rotation done. inside callback.')
    end)
print('stepper.rotate() - start v2')
stepper.rotate(stepper.REVERSE,desired_steps,interval,timer_to_use,function ()
    print('Rotation done. inside callback. v2')
    end)

