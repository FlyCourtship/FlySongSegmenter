#include "mex.h"
#include "matrix.h"
#include "mat.h"


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

/* Usage: [runs, {lengths}, {starts}] = extract_runs(x, inds); */

 	int *pnLengths, *pnStarts, *pnEnds;
	double *pfInds;
	int nElements,i,j,iRun,nRuns,n,m;
	char bInRun;	
	mxArray *mxTemp;
	double *prData,  *prTemp;
	mxClassID mxIntClass;

	mxIntClass = mxINT32_CLASS;

	switch(sizeof(int))
	{
	case 1:
		mxIntClass = mxINT8_CLASS;
		break;	
	case 2:
		mxIntClass = mxINT16_CLASS;
		break;
	case 4:
		mxIntClass = mxINT32_CLASS;
		break;
	case 8:
		mxIntClass = mxINT64_CLASS;
		break;
	default:
		mexErrMsgTxt("sizeof(int) is not 1,2,4, or 8 bytes.");
		break;
	}
	
	pnLengths = NULL;
	pnStarts = NULL;
	pnEnds = NULL;
		

	if (nrhs!=2)
		mexErrMsgTxt("Usage: [runs, {lengths}, {starts}] = extract_runs(x, inds)\n");

	if (nlhs<1)
	    mexErrMsgTxt("At least one output argument required.\n");

	if (nlhs>3)
		mexErrMsgTxt("At most 3 output arguments required.\n");

	nElements = mxGetNumberOfElements(prhs[1]);

	if (nElements != mxGetNumberOfElements(prhs[0]))
		mexErrMsgTxt("Data and indices vectors must have the same number of elements.\n");

	if (nElements == 0)
	{
		for (i = 0; i<nlhs; i++)
			plhs[i] = mxCreateDoubleMatrix(0,0,mxREAL);
		return;
	}

	if (mxIsComplex(prhs[0]))
		mexErrMsgTxt("Data vector must be real, not complex.");
		
	if (!mxIsDouble(prhs[0]))
		mexErrMsgTxt("Data vector must be of type double. Cast to double before call.");

	if (!mxIsDouble(prhs[1]))
		mexErrMsgTxt("Indices vector must be of type double. Cast to double before call.");
		

	pfInds = mxGetPr(prhs[1]);

	nRuns = 0;
	bInRun = (pfInds[0] == 1);

	for (i = 1; i<nElements; i++)
	{
	    if (bInRun)
	    {
	        if (!pfInds[i])
	        {
	            bInRun = 0;
	            nRuns++;
	        }
	    }
	    else
	    {
	        if (pfInds[i])
	        {
	            bInRun = 1;
	        }
	    }
	}

	if (bInRun)
	    nRuns++;

	if (nRuns)
	{
	    pnLengths	= mxCalloc(nRuns, sizeof(int));
	    pnStarts	= mxCalloc(nRuns, sizeof(int));
	    pnEnds		= mxCalloc(nRuns, sizeof(int));

	    iRun    = 0;
	    bInRun  = (pfInds[0]==1);
    
	    pnStarts[iRun]  = (bInRun) ? 0 : -1;
	    pnEnds[iRun]    = -1;
    
	    for (i = 1; i<nElements; i++)
	    {
	        if (bInRun)
	        {
	            if (pfInds[i]==0)
	            {
	                bInRun = 0;
	                pnEnds[iRun] = i-1;
	                pnLengths[iRun] = pnEnds[iRun] - pnStarts[iRun] + 1;
	                iRun++;
	            }
	        }
	        else
	        {
	            if (pfInds[i]==1)
	            {
	                bInRun = 1;
	                pnStarts[iRun] = i;
	            }
	        }
	    }
    
	    if (bInRun)
	    {
	        pnEnds[iRun] = nElements-1;
			pnLengths[iRun] =  pnEnds[iRun] - pnStarts[iRun] + 1;
	        iRun++;
	    }
    
	    /* Load the runs into the cell */
    
		plhs[0] = mxCreateCellMatrix(nRuns, 1);

		prData = mxGetPr(prhs[0]);
	
	    for (i = 0; i<nRuns;i++)
	    {
	    	mxTemp = mxCreateDoubleMatrix(1, pnLengths[i],  mxREAL);
			
			prTemp = mxGetPr(mxTemp);
			
			m = pnStarts[i];
			n = pnEnds[i];

			for (j = m; j<=n;j++)
			{
				prTemp[j-m] = prData[j];
			}
			
			mxSetCell(plhs[0],i,mxTemp);
	    }


	}
	else
	{
		plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
	}

	switch(nlhs)
	{
		case 3:
			
			if (pnStarts)
			{
				plhs[2] = mxCreateNumericMatrix(1,nRuns,mxIntClass,mxREAL);
        for (i = 0; i<nRuns; i++)
            pnStarts[i]++; /* +1 to account for MATLAB being base 1. */
				mxSetData(plhs[2], pnStarts);
			}
			else
			{
				plhs[2] = mxCreateDoubleMatrix(0,0,mxREAL);
			}
		
		case 2:
			
			if (pnLengths)
			{
				plhs[1] = mxCreateNumericMatrix(1,nRuns,mxIntClass,mxREAL);
				mxSetData(plhs[1], pnLengths);
			}
			else
			{
				plhs[1] = mxCreateDoubleMatrix(0,0,mxREAL);
			}
	}

	if (pnEnds)
		mxFree(pnEnds);

	if (pnStarts && nlhs < 3)
		mxFree(pnStarts);


	if (pnLengths && nlhs < 2)
		mxFree(pnLengths);
}

