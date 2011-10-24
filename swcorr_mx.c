#include "mex.h"
#include "matrix.h"
#include "mat.h"
#include <math.h>

double normalize_signal(double *ps1, int ns1, double *psn)
{
    double sum,s1mean,s1rss;
    int i;
    sum = 0;
    for (i = 0; i<ns1; i++)
    {
        sum += ps1[i];
    }
    
    s1mean = sum/(double)ns1;
    
    sum = 0;
    for (i = 0; i<ns1; i++)
    {
        psn[i] = ps1[i]-s1mean;
        sum += psn[i]*psn[i];
    }
    
    s1rss = sqrt(sum);
    
    return s1rss;   
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    double *ps1, *ps2, *psn1, *psn2, *pc, s1rss, s2rss;
    
    int ns1, ns2, nc, i,j,temp;
       
    if (nrhs!=2)
        mxErrMsgTxt("Need 2 rhs arguments. Usage: swc = swcorr(s1,s2).");

    
    ns1 = mxGetNumberOfElements(prhs[0]);
    ns2 = mxGetNumberOfElements(prhs[1]);
   
    
    if (ns2<ns1)
    {
        ps1 = mxGetPr(prhs[1]);
        ps2 = mxGetPr(prhs[0]);
        temp = ns1;
        ns1 = ns2;
        ns2 = temp;
    }
    else
    {
        ps1 = mxGetPr(prhs[0]);
        ps2 = mxGetPr(prhs[1]);
    }
  
   
    nc = ns2-ns1+1;
    
    plhs[0] = mxCreateDoubleMatrix(1,nc,mxREAL);
    pc = mxGetPr(plhs[0]);

    psn1 = mxCalloc(ns1,sizeof(double));
    psn2 = mxCalloc(ns1,sizeof(double));
    
    s1rss = normalize_signal(ps1,ns1,psn1);
    
    if (s1rss == 0)
    {
        for (i = 0; i<nc; i++)
           pc[i] = -2;
    }
    else
    {    
        for (i = 0; i<nc;i++)
        {
            s2rss = normalize_signal((ps2+i),ns1,psn2);
            if (s2rss==0)
            {
                pc[i] = -2;
            }
            else
            {
                pc[i] = 0;
                for (j = 0; j<ns1; j++)
                {
                    pc[i] += psn1[j]*psn2[j]; 
                }
                pc[i] /= (s1rss*s2rss);
                if (pc[i]>1) pc[i] = 1;
                if (pc[i]<-1) pc[i] = -1;
            }
        }
    }
    
    mxFree(psn1);
    mxFree(psn2);    
}

