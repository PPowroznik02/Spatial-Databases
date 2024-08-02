import mapbox


apiKey = "sk.eyJ1IjoicHBvd3Jvem5payIsImEiOiJjbHJkeDR3angxZWx1MmpwanRremdnaW0yIn0.vnImQ939yy3sbrmJYhEL_w"
filePath = r"C:\Users\ppowr\Desktop\T2019_KAR_POI_TABLE.json"

service = mapbox.Uploader(apiKey)

res = service.upload(filePath, "T2019_KAR_POI_TAB")
