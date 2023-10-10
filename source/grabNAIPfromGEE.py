# import geemap
import ee



 ee.Initialize(opt_url='https://earthengine-highvolume.googleapis.com')
  
  items = getRequests()

  pool = multiprocessing.Pool(25)
  pool.starmap(getResult, enumerate(items))
  pool.close()
  pool.join()


