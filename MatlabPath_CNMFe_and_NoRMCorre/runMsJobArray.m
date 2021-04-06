JOB_ID=getenv('JOB_ID');
SGE_TASK_ID=getenv('SGE_TASK_ID');
mydir=getenv('mydir')

[status,cmdout] = system('ls -1 ${mydir} | head -n ${SGE_TASK_ID} | tail -n 1')

if status == 0;
  runMsCluster([mydir cmdout]);
end
