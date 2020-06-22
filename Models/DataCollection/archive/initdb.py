
import database
import utils

DATABASE='archive'

db = database.initdb(DATABASE)

# read ids from csv
data = utils.import_csv('../../../Data/processed/processed_20170320/addresses.csv',';')

ids = [{id:int(row[0]),ts:0} for row in data]

db['ids'].insert_many(ids)

db['ids'].create_index([("ts", pymongo.ASCENDING)])
