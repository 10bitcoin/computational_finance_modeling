#%%
"""
Created on Nov 15 2019
Stochastic integration of int_0^1W^4(t)dW(t)
@author: Lech A. Grzelak
"""
import numpy as np
import matplotlib.pyplot as plt

# We simulate paths for dX(t) = W(t) dW(t) with X(t_0)=0
def GenerateMonteCarloPaths(NoOfPaths,NoOfSteps,T):    
    Z = np.random.normal(0.0,1.0,[NoOfPaths,NoOfSteps])
    X = np.zeros([NoOfPaths, NoOfSteps+1])
    W = np.zeros([NoOfPaths, NoOfSteps+1])

    dt = T / float(NoOfSteps)
    t = 0.0
    for i in range(0,NoOfSteps):
        # making sure that samples from normal have mean 0 and variance 1
        if NoOfPaths > 1:
            Z[:,i] = (Z[:,i] - np.mean(Z[:,i])) / np.std(Z[:,i])
        W[:,i+1] = W[:,i] + np.power(dt, 0.5)*Z[:,i]
        X[:,i+1] = X[:,i] + W[:,i]**4.0 * (W[:,i+1]-W[:,i])
        t = t + dt
    return X

def mainCalculation():
    NoOfPaths = 10000
    NoOfSteps = 100
    T = 2
    X = GenerateMonteCarloPaths(NoOfPaths,NoOfSteps,T)
        
    EX_T = np.mean(X[:,-1])
    VarX_T = np.var(X[:,-1])
    print("E(X(T)) = {0:4e}  and Var(X(T))={1:4f}".format(EX_T,VarX_T))
    EX_theo = 0.0
    VarX_theo = 21*T**5.0
    print("Exact solution: E(X(T)) = {0:4e}  and Var(X(T))={1:4f}".format(EX_theo,VarX_theo))
    plt.figure(1)
    plt.plot(np.linspace(0,T,NoOfSteps+1), np.transpose(X))   
    plt.grid()
    plt.xlabel("time")
    plt.ylabel("X(t)")
    
    plt.figure(2)
    plt.grid()
    plt.hist(X[:,-1],25)
    

mainCalculation()