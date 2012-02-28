
for i = 1:size(ipis,2);
   train_length(i) = sum(ipis{i});
   pulses_per_train(i) = length(ipis{i})+1; 
   meanIPI_train(i) = mean(ipis{i});
   stdIPI_train(i) = std(ipis{i});
end

%plot the IPI trends:
yf=[];
rsquare=[];
n=1;
for i=1:size(ipis,2);
aa=length(ipis{i});
if aa>5; %if there are at least 6 pulses in the train
vect = (1:aa);
[cfun,cfit,output] = fit(vect', ipis{i}', 'exp1'); %exp1: Y = a*exp(b*x)
rsquare(i) = cfit.adjrsquare;
const = cfun.b;
mult = cfun.a;
xf = linspace(1,60,60);
    if cfit.adjrsquare>0.5; %if rsquare value is > 0.5
    train(n) = i;
    yf(n,:) = exp(const*xf);
    n=n+1;
    end
end
end

h=figure(1); for i=1:size(yf,1);
hold on; plot(yf(i,:));
end
ylim([0 5]); title('exponential fits of IPIs within a train');

