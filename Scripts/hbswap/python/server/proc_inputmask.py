import leveldb
import sys
import time

from utils import to_hex, p

if __name__ == "__main__":
    server_id = sys.argv[1]
    init_idx = int(sys.argv[2])

    while True:
        try:
            db = leveldb.LevelDB(f"Scripts/hbswap/db/server{server_id}")
            break
        except leveldb.LevelDBError:
            time.sleep(3)

    file = f"PreProcessing-Data/4-MSp-255/Randoms-MSp-P{server_id}"
    with open(file, "r") as f:
        idx = init_idx
        for line in f.readlines():
            data = int(line) % p
            if idx == init_idx:
                print(idx, data)
            db.Put(f"inputmask_{idx}".encode(), to_hex(str(data)))
            idx += 1
