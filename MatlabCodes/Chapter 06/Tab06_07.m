function CGMY_COS_Convergence
clc;clf;close all;
format short e

% Characteristic function parameters 

S0    = 100;
r     = 0.1;
sigma = 0.2;
C     = 1.0;
G     = 5.0;
M     = 5.0;
Y     = 0.5;
t     = 1.0;
CP    = 'c';

% Range of strike prices

K      = [S0]; 
L      = 8;

% Characteristic function of the CGMY model

cf = ChFCGMY(r,t,C,G,M,Y,sigma);

% Reference option price with 2^14 number of expansion elements

callPriceExact = CallPutOptionPriceCOSMthd(cf,CP,S0,r,t,K,2.^14,L);

% Number of expansion terms

N = [4,8,16,24,32,36,40,48,64,80,96,128];

idx = 1;
error = zeros(length(N),1);
for n = N
    callPriceN = CallPutOptionPriceCOSMthd(cf,CP,S0,r,t,K,n,L);
    error(idx) = abs(callPriceN- callPriceExact);
    sprintf('Abs error for n= %.2f is equal to %.2E',n,error(idx))
    idx = idx +1;
end

function cf = ChFCGMY(r,tau,C,G,M,Y,sigma)
i = complex(0,1);
varPhi = @(u) exp(tau * C *gamma(-Y)*(( M-i*u).^Y - M^Y + (G+i*u).^Y - G^Y));
omega  = -1/tau * log(varPhi(-i));
cf     = @(u) varPhi(u) .* exp(i*u* (r+ omega -0.5*sigma^2)*tau - 0.5*sigma^2 *u .*u *tau);

function value = CallPutOptionPriceCOSMthd(cf,CP,S0,r,tau,K,N,L)
i = complex(0,1);

% cf   - Characteristic function, in the book denoted as \varphi
% CP   - C for call and P for put
% S0   - Initial stock price
% r    - Interest rate (constant)
% tau  - Time to maturity
% K    - Vector of strikes
% N    - Number of expansion terms
% L    - Size of truncation domain (typ.:L=8 or L=10)  

x0 = log(S0 ./ K);   

% Truncation domain

a = 0 - L * sqrt(tau); 
b = 0 + L * sqrt(tau);

k = 0:N-1;              % Row vector, index for expansion terms
u = k * pi / (b - a);   % ChF arguments

H_k = CallPutCoefficients('P',a,b,k);
temp    = (cf(u) .* H_k).';
temp(1) = 0.5 * temp(1);      % Multiply the first element by 1/2

mat = exp(i * (x0 - a) * u);  % Matrix-vector manipulations

% Final output

value = exp(-r * tau) * K .* real(mat * temp);

% Use the put-call parity to determine call prices (if needed)

if lower(CP) == 'c' || CP == 1
    value = value + S0 - K*exp(-r*tau);    
end

% Coefficients H_k for the COS method

function H_k = CallPutCoefficients(CP,a,b,k)
    if lower(CP) == 'c' || CP == 1
        c = 0;
        d = b;
        [Chi_k,Psi_k] = Chi_Psi(a,b,c,d,k);
         if a < b && b < 0.0
            H_k = zeros([length(k),1]);
         else
            H_k = 2.0 / (b - a) * (Chi_k - Psi_k);
         end
    elseif lower(CP) == 'p' || CP == -1
        c = a;
        d = 0.0;
        [Chi_k,Psi_k]  = Chi_Psi(a,b,c,d,k);
         H_k = 2.0 / (b - a) * (- Chi_k + Psi_k);       
    end

function [chi_k,psi_k] = Chi_Psi(a,b,c,d,k)
    psi_k        = sin(k * pi * (d - a) / (b - a)) - sin(k * pi * (c - a)/(b - a));
    psi_k(2:end) = psi_k(2:end) * (b - a) ./ (k(2:end) * pi);
    psi_k(1)     = d - c;
    
    chi_k = 1.0 ./ (1.0 + (k * pi / (b - a)).^2); 
    expr1 = cos(k * pi * (d - a)/(b - a)) * exp(d)  - cos(k * pi... 
                  * (c - a) / (b - a)) * exp(c);
    expr2 = k * pi / (b - a) .* sin(k * pi * ...
                        (d - a) / (b - a))   - k * pi / (b - a) .* sin(k... 
                        * pi * (c - a) / (b - a)) * exp(c);
    chi_k = chi_k .* (expr1 + expr2);
