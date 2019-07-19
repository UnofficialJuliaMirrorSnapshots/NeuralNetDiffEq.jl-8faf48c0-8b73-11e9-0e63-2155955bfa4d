using Flux, Test, Statistics
using NeuralNetDiffEq, LinearAlgebra

# one-dimensional heat equation
x0 = [11.0]  # initial points
tspan = (0.0,5.0)
dt = 0.5   # time step
time_steps = div(tspan[2]-tspan[1],dt)
d = 1      # number of dimensions
m = 50     # number of trajectories (batch size)

g(X) = sum(X.^2)   # terminal condition
f(X,Y,Z,p,t) = 0.0  # function from solved equation
μ(X,p,t) = 0.0
σ(X,p,t) = 1.0
prob = TerminalPDEProblem(g, f, μ, σ, x0, tspan)

hls = 10 + d #hidden layer size
opt = Flux.ADAM(0.005)  #optimizer
#sub-neural network approximating solutions at the desired point
u0 = Flux.Chain(Dense(d,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,1))
# sub-neural network approximating the spatial gradients at time point
σᵀ∇u = [Flux.Chain(Dense(d,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,d)) for i in 1:time_steps]

# hide_layer_size
alg = NNPDEHan(u0, σᵀ∇u, opt = opt)

ans = solve(prob, alg, verbose = true, abstol=1e-8, maxiters = 300, dt=dt, trajectories=m)

u_analytical(x,t) = sum(x.^2) .+ d*t
analytical_ans = u_analytical(x0, tspan[end])

error_l2 = sqrt((ans-analytical_ans)^2/ans^2)

println("one-dimensional heat equation")
# println("numerical = ", ans)
# println("analytical = " ,analytical_ans)
println("error_l2 = ", error_l2, "\n")
@test error_l2 < 0.1


# high-dimensional heat equation
d = 100 # number of dimensions
x0 = fill(8,d)
tspan = (0.0,2.0)
dt = 0.5
time_steps = div(tspan[2]-tspan[1],dt)
m = 100 # number of trajectories (batch size)

g(X) = sum(X.^2)
f(X,Y,Z,p,t) = 0.0
μ(X,p,t) = 0.0
σ(X,p,t) = 1.0
prob = TerminalPDEProblem(g, f, μ, σ, x0, tspan)


hls = 10 + d #hidden layer size
# hide_layer_size
#sub-neural network approximating solutions at the desired point
u0 = Flux.Chain(Dense(d,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,1))
# sub-neural network approximating the spatial gradients at time point
σᵀ∇u = [Flux.Chain(Dense(d,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,d)) for i in 1:time_steps]

alg = NNPDEHan(u0, σᵀ∇u, opt = opt)

ans = solve(prob, alg, verbose = true, abstol=1e-8, maxiters = 400, dt=dt, trajectories=m)

u_analytical(x,t) = sum(x.^2) .+ d*t
analytical_ans = u_analytical(x0, tspan[end])
error_l2 = sqrt((ans - analytical_ans)^2/ans^2)

println("high-dimensional heat equation")
# println("numerical = ", ans)
# println("analytical = " ,analytical_ans)
println("error_l2 = ", error_l2, "\n")
@test error_l2 < 0.1


#Black-Scholes-Barenblatt equation
d = 100 # number of dimensions
x0 = repeat([1, 0.5], div(d,2))
tspan = (0.0,1.0)
dt = 0.25
time_steps = div(tspan[2]-tspan[1],dt)
m = 100 # number of trajectories (batch size)

r = 0.05
sigma_max = 0.4
f(X,Y,Z,p,t) = r * (Y .- sum(X.*Z)) # M x 1
g(X) = sum(X.^2)  # M x D
μ(X,p,t) = 0.0
σ(X,p,t) = Diagonal(sigma_max*X)
prob = TerminalPDEProblem(g, f, μ, σ, x0, tspan)

hls  = 10 + d #hide layer size
opt = Flux.ADAM(0.001)
u0 = Flux.Chain(Dense(d,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,1))
σᵀ∇u = [Flux.Chain(Dense(d,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,d)) for i in 1:time_steps]

alg = NNPDEHan(u0, σᵀ∇u, opt = opt)

ans = solve(prob, alg, verbose = true, abstol=1e-8, maxiters = 250, dt=dt, trajectories=m)

u_analytical(x, t) = exp((r + sigma_max^2).*(tspan[end] .- tspan[1])).*sum(x.^2)
analytical_ans = u_analytical(x0, tspan[1])
error_l2 = sqrt((ans .- analytical_ans)^2/ans^2)

println("Black Scholes Barenblatt equation")
# println("numerical ans= ", ans)
# println("analytical ans = " , u_analytical(x0, t0))
println("error_l2 = ", error_l2, "\n")
@test error_l2 < 0.1


# Allen-Cahn Equation
d = 20 # number of dimensions
x0 = fill(0,d)
tspan = (0.0,0.3)
dt = 0.015 # time step
time_steps = div(tspan[2]-tspan[1], dt)
m = 100 # number of trajectories (batch size)

g(X) = 1.0 / (2.0 + 0.4*sum(X.^2))
f(X,Y,Z,p,t) =  Y .- Y.^3  # M x 1
μ(X,p,t) = 0.0
σ(X,p,t) = 1.0
prob = TerminalPDEProblem(g, f, μ, σ, x0, tspan)

hls = 10 + d #hidden layer size
opt = Flux.ADAM(5^-4)  #optimizer
#sub-neural network approximating solutions at the desired point
u0 = Flux.Chain(Dense(d,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,1))

# sub-neural network approximating the spatial gradients at time point
σᵀ∇u = [Flux.Chain(Dense(d,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,d)) for i in 1 : time_steps]

# hide_layer_size
alg = NNPDEHan(u0, σᵀ∇u, opt = opt)

ans = solve(prob, alg, verbose = true, abstol=1e-8, maxiters = 400, dt=dt, trajectories=m)

prob_ans = 0.30879
error_l2 = sqrt((ans - prob_ans)^2/ans^2)

println("Allen-Cahn equation")
# println("numerical = ", ans)
# println("prob_ans = " , prob_ans)
println("error_l2 = ", error_l2, "\n")
@test error_l2 < 0.1


#Hamilton Jacobi Bellman Equation
d = 100 # number of dimensions
x0 = fill(0,d)
tspan = (0.0, 1.0)
dt = 0.2
ts = tspan[1]:dt:tspan[2]
time_steps = length(ts)-1
m = 100 # number of trajectories (batch size)

g(x) = log(0.5 + 0.5*sum(x.^2))
f(X,Y,Z,p,t) = sum(Z.^2)
μ(X,p,t) = 0.0
σ(X,p,t) = sqrt(2)
prob = TerminalPDEProblem(g, f, μ, σ, x0, tspan)

hls = 10 + d #hidden layer size
opt = Flux.ADAM(0.001)  #optimizer
#sub-neural network approximating solutions at the desired point
u0 = Flux.Chain(Dense(d,hls,relu),
                Dense(hls,hls,relu),
                Dense(hls,1))

# sub-neural network approximating the spatial gradients at time point
σᵀ∇u = [Flux.Chain(Dense(d,hls,relu),
                  Dense(hls,hls,relu),
                  Dense(hls,d)) for i in 1 : time_steps]

# hide_layer_size
alg = NNPDEHan(u0, σᵀ∇u, opt = opt)

ans = solve(prob, alg, verbose = true, abstol=1e-8, maxiters = 600, dt=dt, trajectories=m)

T = tspan[2]
NC = length(ts)
MC = 10^5
W() = randn(d,NC)
u_analytical(x, ts) = -log(mean(exp(-g(x .+ sqrt(2.0)*abs.(T.-ts').*W())) for _ = 1:MC))
analytical_ans = u_analytical(x0, ts)

error_l2 = sqrt((ans - analytical_ans)^2/ans^2)

println("Hamilton Jacobi Bellman Equation")
# println("numerical = ", ans)
# println("analytical = " , analytical_ans)
println("error_l2 = ", error_l2, "\n")
@test error_l2 < 0.2
