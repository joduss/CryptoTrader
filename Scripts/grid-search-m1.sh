echo Copying....

ssh admin@192.168.1.50 "rm /Users/admin/Desktop/Jonathan/simulation/CryptoTrader"
scp /Users/jonathanduss/Library/Developer/Xcode/DerivedData/CryptoTrader-comppumrkontvwbrwwwxanmpsvyt/Build/Products/Release/CryptoTrader admin@192.168.1.50:/Users/admin/Desktop/Jonathan/simulation/CryptoTrader


cd /Users/jonathanduss/Downloads/Trader2/Scripts/

#ssh admin@192.168.1.50
cat script-for-mac-m1.sh | ssh admin@192.168.1.50 'bash -s'