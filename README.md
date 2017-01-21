# Particle-Simulation
Hansen Zhao : zhaohs12@163.com

### Init Field
```
p = ParticleField(1,0)  
```
init a field with diffuse coefficient of 1.0 and bias of 0.0
bias should be set ranging from -1.0 to 1.0, the sign of bias means the direction of movement that the particle likely to take in every movement in this region  
absolute value of bias means the probability of forcing the particle to move along the direction
For example, bias = -0.5 means a probability of 50% where the program will force the particle move to -inf direction.

### addRegion
```
p.addRegion([-1,1],0.2,1);  
```
add a region from -1 to 1 with diffuse coefficient of 0.2 and bias of 1.0
```
p.addRegion(-5,2,0.2,'left'); 
```
add a region from -inf to -5 with diffuse coeficient of 2 and bias of 0.2

### display field state
```
p.dispField();  
```
follow the command above, and will create a field like:  
```
<-Inf> 2.00$0.20 <-5.0> 1.00$0.00 <-1.0> 0.20$1.00 <1.0> 1.00$0.00 <Inf>  
```
```
\<a\> b$c \<d\>  
```
means region from a to d with diffuse coefficient of b and bias of c

### addParticle
```
p.addParticle(1,-3);  
```
add 1 particle with init position of -3

### simulation
```
p.simulate(3000,0.01);  
```
simulation with step length of 3000 and interval of 0.01

### view result
```
p.plotSimu();  
```
plot result in two figure, the left one is time-position, while right one is time-velocity

### get Result
```
pos = p.getSimuResult();  
```
get position result of all particles
```
vel = p.getSimuVel();  
```
get velocity result of all particles
```
pos = p.getSimuResult(1);  
```
get position result of particle 1
```
vel = p.getSimuVel(1);  
```
get velocity result of particle 1
