% =========================================================================
% computes the steady-state of a growth variant of the Baxter and King (1993, AER) model
% =========================================================================
% Willi Mutschler (willi@mutschler.eu)
% Version: April 26, 2023
% =========================================================================

%-------------------------------------------------------------------------%
% declare variables and parameters
% var, varexo and parameters are Dynare blocks, they end with a semicolon
% note that you can use either % or // for comments in a mod file
%-------------------------------------------------------------------------%
var 
  y   // output (detrended)
  c   // consumption (detrended)
  iv  // private investment (detrended)
  gb  // basic government spending (detrended)
  ivg // government investment (detrended)
  k   // private capital stock (detrended)
  kg  // public capital stock (detrended)
  rk  // real interest rate
  w   // real wage (detrended)
  tau // net tax rate
  tr  // fiscal transfers (detrended)
  n   // labor
;

varexo
  e_gb  // government spending shock
  e_ivg // government investment shock
  e_tau // tax rate shock
;

parameters 
  BETA    // discount factor
  THETA_L // utility weight for leisure in utility function
  DELTA_K // capital depreciation rate  
  THETA_G // public capital productivity in production function
  THETA_K // private capital productivity in production function
  THETA_N // labor productivity in production function
  RHO_GB  // persistence parameter basic government spending process
  RHO_IVG // persistence parameter government investment process
  RHO_TAU // persistence parameter tax process
  GB_BAR  // target value of basic government spending
  IVG_BAR // target value of government investment
  TAU_BAR // target value of tax rate
  GAMMAX  // steady-state growth rate
;

%-------------------------------------------------------------------------%
% calibrate parameters
% this is actual MATLAB code; Dynare will use variables that have the same
% name as a declared parameter to initialize entries in M_.params
%-------------------------------------------------------------------------%
% parameter calibration using targeted steady-state values
GAMMAX  = 1+0.06/4; % 1.6% growth per annum, note that we aim for a quarterly calibration
Y_BAR   = 10; % normalize higher than 1 otherwise consumption might be negative
GB_BAR  = 0.2*Y_BAR;
IVG_BAR = 0.02*Y_BAR;
TR_BAR  = 0;
W_BAR   = 2;
N_BAR   = 1/3;
DELTA_K = 0.025; % standard quarterly value (see e.g. RBC model)
KG_BAR  = IVG_BAR/(GAMMAX-1+DELTA_K); % from public capital law of motion in steady-state
THETA_N = W_BAR*N_BAR/Y_BAR; % from labor demand in steady-state
% constant returns to scale over all provided inputs: THETA_N+THETA_K+THETA_G=1
% combined with public capital productivity should be lower than capital share in production
THETA_G = 0.3*(1-THETA_N);
THETA_K = 1-THETA_N-THETA_G;
K_BAR   = (Y_BAR/(KG_BAR^THETA_G*N_BAR^THETA_N))^(1/THETA_K); % from production function
IV_BAR  = K_BAR*(GAMMAX-1+DELTA_K); % private capital accumulation
C_BAR   = Y_BAR - IV_BAR - GB_BAR - IVG_BAR; % from ressource constraint in steady-state
RK_BAR  = THETA_K*Y_BAR/K_BAR; % from capital demand
TAU_BAR = (GB_BAR + IVG_BAR + TR_BAR)/(W_BAR*N_BAR+RK_BAR*K_BAR); % fiscal budget ins steady-state

BETA    = GAMMAX/(1-DELTA_K+(1-TAU_BAR)*RK_BAR);  % from savings decision in steady-state
THETA_L = (1-TAU_BAR)*W_BAR*(1-N_BAR)/C_BAR; % labor utility weight from labor supply decision

% same persistence of exogenous processes
RHO_GB  = 0.75;
RHO_IVG = 0.75;
RHO_TAU = 0.75;

%-------------------------------------------------------------------------%
% model equations
% this is a Dynare block, don't forget the semicolons after model and after each equation!
%-------------------------------------------------------------------------%
model;

[name='law of motion private capital stock']
GAMMAX*k = (1-DELTA_K)*k(-1) + iv;
[name='law of motion public capital stock']
GAMMAX*kg = (1-DELTA_K)*kg(-1) + ivg;
[name='labor-leisure decision']
(1-tau)*w = THETA_L*c/(1-n);
[name='savings decision']
GAMMAX*c(+1)/c = BETA*(1-DELTA_K + (1-tau(+1))*rk(+1));
[name='production function']
y = n^THETA_N * k(-1)^THETA_K * kg(-1)^THETA_G;
[name='labor demand']
w*n = THETA_N*y;
[name='private capital demand']
rk*k(-1) = THETA_K*y;
[name='government budget constraint']
gb + ivg = tau*(w*n + rk*k(-1)) - tr;
[name='fiscal rule: government spending']
gb - GB_BAR = RHO_GB*(gb(-1)-GB_BAR) + e_gb;
[name='fiscal rule: government investment']
ivg - IVG_BAR = RHO_IVG*(ivg(-1)-IVG_BAR) + e_ivg;
[name='fiscal rule: tax rate']
log(tau/TAU_BAR) = RHO_TAU*log(tau(-1)/TAU_BAR) + e_tau;
[name='market clearing']
y = c + iv + gb + ivg;

end;

%-------------------------------------------------------------------------%
% steady-state computations
% initval is a Dynare block specifying the initial values for an optimizer
%-------------------------------------------------------------------------%
% note that above we already computed the steady-state for all variables,
% so instead of a steady_state_model block we can also just use initval instead.
% That is, a numerical fixed point solver with initial value already equal
% to the analytically computed steady-state.
initval;
y   = Y_BAR;
c   = C_BAR;
iv  = IV_BAR;
gb  = GB_BAR;
ivg = IVG_BAR;
k   = K_BAR;
kg  = KG_BAR;
rk  = RK_BAR;
w   = W_BAR;
tau = TAU_BAR;
tr  = TR_BAR;
n   = N_BAR;
end;
steady; % compute steady-state