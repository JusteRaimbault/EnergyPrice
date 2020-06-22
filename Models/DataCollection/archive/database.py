import pymongo

DATABASE = 'archive'

def initdb():
    mongo = pymongo.MongoClient(open('mongopath','r'))
    return(mongo[DATABASE])

def get_oldest(collection):
    return(collection.find_one_and_delete({ts:{$min:'ts'}}))
