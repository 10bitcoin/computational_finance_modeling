function BatesImpliedVolatility
clc;clf;close all;

% Option parameters

T      = 1;
S0     = 100;
CP     = 'c';

% Heston model part

kappa  = 1.2;
gamma  = 0.05;
vBar   = 0.05;
rho    = -0.75;
v0     = 0.05;
r      = 0.00;

% Bates model

muJ    = 0.0;
sigmaJ = 0.2;
xiP    = 0.1;

% Range of strike prices

K      = linspace(40,180,25)'; 

% COS method settings

N = 1000;
L = 5;

% Effect of xi_P

xiPV =[0.01, 0.1, 0.2, 0.3];
ivM = zeros(length(K),length(xiPV));
argLegend = cell(5,1);
idx = 1;
for i=1:length(xiPV)
    xiPTemp = xiPV(i);

    % Compute ChF for the Bates model

    cf = @(u) ChFBates(u, T, kappa,vBar,gamma,rho, v0, r, muJ, sigmaJ, xiPTemp);

    % The COS method

    optPrice = CallPutOptionPriceCOSMthd(cf,CP,S0,r,T,K,N,L);
    for j = 1:length(K)
        strike = K(j);
        call   = optPrice(j);
        ivM(j,i) = ImpliedVolatility(CP,call,strike,T,S0,r,0.3)*100;
    end
    argLegend{idx} = sprintf('xiP=%.2f',xiPTemp);
    idx = idx + 1;
end
MakeFigure(K, ivM,argLegend,'Effect of \xi_P on implied volatility')

% Effect of mu_J

muJV =[-0.5, -0.25, 0, 0.25];
ivM = zeros(length(K),length(xiPV));
argLegend = cell(5,1);
idx = 1;
for i=1:length(muJV)
    muJTemp = muJV(i);

    % Compute ChF for the Bates model

    cf = @(u) ChFBates(u, T, kappa,vBar,gamma,rho, v0, r, muJTemp, sigmaJ, xiP);

    % The COS method

    optPrice = CallPutOptionPriceCOSMthd(cf,CP,S0,r,T,K,N,L);
    for j = 1:length(K)
        strike = K(j);
        call   = optPrice(j);
        ivM(j,i) = ImpliedVolatility(CP,call,strike,T,S0,r,0.3)*100;
    end
    argLegend{idx} = sprintf('mu_J=%.2f',muJTemp);
    idx = idx + 1;
end
MakeFigure(K, ivM,argLegend,'Effect of \mu_J on implied volatility')

% Effect of sigma_J

sigmaJV =[0.01, 0.15, 0.2, 0.25];
ivM = zeros(length(K),length(xiPV));
argLegend = cell(5,1);
idx = 1;
for i=1:length(sigmaJV)
    sigmaJTemp = sigmaJV(i);

    % Compute ChF for the Bates model

    cf = @(u) ChFBates(u, T, kappa,vBar,gamma,rho, v0, r, muJ, sigmaJTemp, xiP);

    % The COS method

    optPrice = CallPutOptionPriceCOSMthd(cf,CP,S0,r,T,K,N,L);
    for j = 1:length(K)
        strike = K(j);
        call   = optPrice(j);
        ivM(j,i) = ImpliedVolatility(CP,call,strike,T,S0,r,0.3)*100;
    end
    argLegend{idx} = sprintf('sigma_J=%.2f',sigmaJTemp);
    idx = idx + 1;
end
MakeFigure(K, ivM,argLegend,'Effect of \sigma_J on implied volatility')


function cf=ChFBates(u, tau, kappa,vBar,gamma,rho, v0, r, muJ, sigmaJ, xiP)
i     = complex(0,1);

% functions D_1 and g

D_1  = sqrt(((kappa -i*rho*gamma.*u).^2+(u.^2+i*u)*gamma^2));
g    = (kappa- i*rho*gamma*u-D_1)./(kappa-i*rho*gamma*u+D_1);    

% Complex-valued functions A and C

C = (1/gamma^2)*(1-exp(-D_1*tau))./(1-g.*exp(-D_1*tau)).*(kappa-gamma*rho*i*u-D_1);
A = i*u*r*tau + kappa*vBar*tau/gamma^2 * (kappa-gamma*rho*i*u-D_1)-2*kappa*vBar/gamma^2*log((1-g.*exp(-D_1*tau))./(1-g));

% Adjustment for the Bates model

A = A - xiP*i*u*tau*(exp(muJ+1/2*sigmaJ^2)-1) + xiP*tau*(exp(i*u*muJ-1/2*sigmaJ^2*u.^2)-1);

% ChF for the Bates model

cf = exp(A + C * v0);

function value = CallPutOptionPriceCOSMthd(cf,CP,S0,r,tau,K,N,L)
i = complex(0,1);


% cf   - Characteristic function, in the book denoted as \varphi
% CP   - C for call and P for put
% S0   - Initial stock price
% r    - Interest rate (constant)
% tau  - Time to maturity
% K    - Vector of strike prices
% N    - Number of expansion terms
% L    - Size of truncation domain (typ.:L=8 or L=10)

x0 = log(S0 ./ K);   

% Truncation domain

a = 0 - L * sqrt(tau); 
b = 0 + L * sqrt(tau);

k = 0:N-1;              % Row vector, index for expansion terms
u = k * pi / (b - a);   % ChF arguments

H_k = CallPutCoefficients(CP,a,b,k);
temp    = (cf(u) .* H_k).';
temp(1) = 0.5 * temp(1);      % Multiply the first element by 1/2

mat = exp(i * (x0 - a) * u);  % Matrix-vector manipulations

% Final output

value = exp(-r * tau) * K .* real(mat * temp);

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
    
% Closed-form expression of European call/put option with Black-Scholes formula

function value=BS_Call_Option_Price(CP,S_0,K,sigma,tau,r)

% Black-Scholes call option price

d1    = (log(S_0 ./ K) + (r + 0.5 * sigma^2) * tau) / (sigma * sqrt(tau));
d2    = d1 - sigma * sqrt(tau);
if lower(CP) == 'c' || lower(CP) == 1
    value =normcdf(d1) * S_0 - normcdf(d2) .* K * exp(-r * tau);
elseif lower(CP) == 'p' || lower(CP) == -1
    value =normcdf(-d2) .* K*exp(-r*tau) - normcdf(-d1)*S_0;
end

function impliedVol = ImpliedVolatility(CP,marketPrice,K,T,S_0,r,initialVol)
    func = @(sigma) (BS_Call_Option_Price(CP,S_0,K,sigma,T,r) - marketPrice).^1.0;
    impliedVol = fzero(func,initialVol);

function figure1= MakeFigure(X1, YMatrix1, argLegend,titleIn)

%CREATEFIGURE(X1,YMATRIX1)
%  X1:        Vector of x data
%  YMATRIX1:  Matrix of y data

%  Auto-generated by MATLAB on 16-Jan-2012 15:26:40

% Create figure

figure1 = figure('InvertHardcopy','off',...
    'Colormap',[0.061875 0.061875 0.061875;0.06875 0.06875 0.06875;0.075625 0.075625 0.075625;0.0825 0.0825 0.0825;0.089375 0.089375 0.089375;0.09625 0.09625 0.09625;0.103125 0.103125 0.103125;0.11 0.11 0.11;0.146875 0.146875 0.146875;0.18375 0.18375 0.18375;0.220625 0.220625 0.220625;0.2575 0.2575 0.2575;0.294375 0.294375 0.294375;0.33125 0.33125 0.33125;0.368125 0.368125 0.368125;0.405 0.405 0.405;0.441875 0.441875 0.441875;0.47875 0.47875 0.47875;0.515625 0.515625 0.515625;0.5525 0.5525 0.5525;0.589375 0.589375 0.589375;0.62625 0.62625 0.62625;0.663125 0.663125 0.663125;0.7 0.7 0.7;0.711875 0.711875 0.711875;0.72375 0.72375 0.72375;0.735625 0.735625 0.735625;0.7475 0.7475 0.7475;0.759375 0.759375 0.759375;0.77125 0.77125 0.77125;0.783125 0.783125 0.783125;0.795 0.795 0.795;0.806875 0.806875 0.806875;0.81875 0.81875 0.81875;0.830625 0.830625 0.830625;0.8425 0.8425 0.8425;0.854375 0.854375 0.854375;0.86625 0.86625 0.86625;0.878125 0.878125 0.878125;0.89 0.89 0.89;0.853125 0.853125 0.853125;0.81625 0.81625 0.81625;0.779375 0.779375 0.779375;0.7425 0.7425 0.7425;0.705625 0.705625 0.705625;0.66875 0.66875 0.66875;0.631875 0.631875 0.631875;0.595 0.595 0.595;0.558125 0.558125 0.558125;0.52125 0.52125 0.52125;0.484375 0.484375 0.484375;0.4475 0.4475 0.4475;0.410625 0.410625 0.410625;0.37375 0.37375 0.37375;0.336875 0.336875 0.336875;0.3 0.3 0.3;0.28125 0.28125 0.28125;0.2625 0.2625 0.2625;0.24375 0.24375 0.24375;0.225 0.225 0.225;0.20625 0.20625 0.20625;0.1875 0.1875 0.1875;0.16875 0.16875 0.16875;0.15 0.15 0.15],...
    'Color',[1 1 1]);

% Create axes

%axes1 = axes('Parent',figure1,'Color',[1 1 1]);
axes1 = axes('Parent',figure1);
grid on

% Uncomment the following line to preserve the X-limits of the axes
% xlim(axes1,[45 160]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(axes1,[19 26]);
% Uncomment the following line to preserve the Z-limits of the axes
% zlim(axes1,[-1 1]);

box(axes1,'on');
hold(axes1,'all');

% Create multiple lines using matrix input to plot
% plot1 = plot(X1,YMatrix1,'Parent',axes1,'MarkerEdgeColor',[0 0 0],...
%     'LineWidth',1,...
%     'Color',[0 0 0]);

plot1 = plot(X1,YMatrix1,'Parent',axes1,...
    'LineWidth',1.5);
set(plot1(1),'Marker','diamond','DisplayName',argLegend{1});
set(plot1(2),'Marker','square','LineStyle','-.',...
    'DisplayName',argLegend{2});
set(plot1(3),'Marker','o','LineStyle','-.','DisplayName',argLegend{3});
set(plot1(4),'DisplayName',argLegend{4});

% Create xlabel

xlabel({'K'});

% Create ylabel

ylabel({'implied volatility [%]'});

% Create title

title(titleIn);

% Create legend

legend1 = legend(axes1,'show');
set(legend1,'Color',[1 1 1]);

