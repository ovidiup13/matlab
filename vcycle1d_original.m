% Recursive V cycle multigrid algorithm for 1D Poisson problem with damped
% Jacobi for pre and post smoothing

% n is the number of unknowns of the form n = 2^k-1
% T is matrix of coefficients and b is rhs vector
% w is the damping coefficient for damped_jacobi
% TOL is the tolerance level for convergence (need 1e-8 here)
% levels is the number of levels to go through (usually 4)

function [x] = vcycle1d_original(n, b, T, w, TOL,levels,x)


res = b - T*x;
if norm(res) > TOL
    % generate restriction matrix
    
    % pre-smoothing with damped Jacobi (do 3 iterations only)
    x = damped_jacobiM(w, x, T, b, 1e-7, 3);
    
    % compute the residual
    res = b - T*x;
    
    
    k = log2(n+1);
    
    N = 2^(k-1)-1;
    
    RE = zeros(N,n);
    
    for i = 1:N
        RE(i,2*i-1:2*i+1) = [1 2 1];
    end
    
    RE = RE/4;
    
    % generate interpolation matrix
    II = 2*RE';
    
    % transfer residual to coarse grid; v is coarse grid residual
    v = zeros(N, 1);
    
    for i = 1:N
        v(i) = (res(2*i-1) + 2*res(2*i) + res(2*i+1))/4;
    end
    
    % transfer matrix T to coarse grid
    TC = RE * T * II;
    
    if levels ~= 1
        [err] = vcycle1d_original(N, v, TC, w, TOL,levels-1,zeros(size(v)));
    else
        
        % solve residual equation to find error
        err = TC\v;
        
    end
    % transfer error to fine grid; r is fine grid error
    erf = zeros(length(b), 1);
    
    erf(1) = err(1)/2;
    
    for j = 1:n/2
        erf(2*j) = err(j);
    end
    
    for j = 1:n/2-1
        erf(2*j+1) = (err(j) + err(j+1))/2;
    end
    
    erf(n) = err(length(err))/2;
    
    % correct approximation (initial guess for damped Jacobi)
    x = x + erf;
    
    % post-smoothing Jacobi (3 iterations)
    x = damped_jacobiM(w, x, T, b, 1e-7, 3);
    
else
    return;
end
end