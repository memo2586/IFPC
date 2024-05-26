import data_rdb from '@ohos.data.rdb'

const STORE_CONFIG = {name: "test.db"}
const TAB_LOG = "log"

const CREATE_TABLE_LOG_CODE = `
    CREATE TABLE IF NOT EXISTS ${TAB_LOG} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        level TEXT,
        info TEXT
    )
`

export function createTable(context) {
  data_rdb.getRdbStore(context, STORE_CONFIG, 1, function (err, rdbStore) {
    if(err){
      console.log("ERROR: Get RdbStore failed, err: " + err)
      return
    }
    rdbStore.executeSql(CREATE_TABLE_LOG_CODE, [], function(err) {
      if (err) {
        console.log("ERROR: ExecuteSql failed, err: " + err)
        return
      }
      console.log('SUCCESS: create table done.')
    })
  })
}

export function insertData(context, item): any {
  const promise = data_rdb.getRdbStore(context, STORE_CONFIG, 1)
  return promise.then(async (rdbStore) => {
    try{
      console.log(`insert : ${item.date}`)
      rdbStore.insert(TAB_LOG, item)
    }catch (err){
      console.log("ERROR: insert failed: " + err)
      return false
    }
    return true
  }).catch((err) => {
    console.log("ERROR: Get RdbStore failed, err: " + err)
  })
}

export function insertDataArr(context, list): any {
  const promise = data_rdb.getRdbStore(context, STORE_CONFIG, 1)
  return promise.then(async (rdbStore) => {
    for(let i: number = 0; i < list.length; i++) {
      const value = {
        "date": list[i].date,
        "level": list[i].level,
        "info": list[i].info
      }
      try{
        console.log(`insert ${i}: ${list[i].date}`)
        rdbStore.insert(TAB_LOG, value)
      }catch (err){
        console.log("ERROR: insert failed: " + err)
        return false
      }
    }
    return true
  }).catch((err) => {
    console.log("ERROR: Get RdbStore failed, err: " + err)
  })
}

export function queryData(context, page:number, pageSize: number): any {
  let promise = data_rdb.getRdbStore(context, STORE_CONFIG, 1)
  return promise.then(async (rdbStore) => {
    // 查询操作
    const offset: number = (page - 1) * pageSize;
    const querySqlString =  `SELECT * FROM ${TAB_LOG} ORDER BY date DESC LIMIT ${pageSize} OFFSET ${offset}`

    try{
      let resultSet = await rdbStore.querySql(querySqlString, [])
      if(resultSet.rowCount == 0) return false
      let list = []
      resultSet.goToFirstRow()
      for(let i = 0; i < resultSet.rowCount; i++){
        const date = resultSet.getString(resultSet.getColumnIndex("date"))
        const level = resultSet.getString(resultSet.getColumnIndex("level"))
        const info = resultSet.getString(resultSet.getColumnIndex("info"))
        resultSet.goToNextRow()
        const data = { date, level, info }
        list.push(data)
        console.log(`query success ${i} : ${date}`)
      }
      resultSet.close()
      return list
    }catch (err){
      console.log("ERROR: query failed, err: " + err)
    }
  }).catch((err) => {
    console.error("ERROR: Get RdbStore failed, err: " + err)
  })
}