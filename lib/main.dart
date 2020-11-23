




//todo_firebase

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  // 最初に表示するWidget
  runApp(ChatApp());
}

// 更新可能なデータ
class UserState extends ChangeNotifier {
  FirebaseUser user;
  void setUser(FirebaseUser newUser) {//登録
    user = newUser;
    notifyListeners();
  }
}

//チャット画面//アプリ起動時の画面
class ChatApp extends StatelessWidget {
  // ユーザーの情報を管理するデータ
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を渡す
    return ChangeNotifierProvider<UserState>.value(
      value: userState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ChatApp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginPage(),
      ),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    //ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // メールアドレス入力
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              // パスワード入力
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,//隠す
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,//横いっぱいにユーザー登録ボタン
                // ユーザー登録ボタン
                child: RaisedButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text('ユーザー登録'),
                  onPressed: () async {//非同期で行う
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final AuthResult result =
                      await auth.createUserWithEmailAndPassword(//ユーザー登録をする
                        email: email,
                        password: password,
                      );
                      final FirebaseUser user = result.user;
                      //ユーザー情報を更新
                      userState.setUser(user);
                      // ユーザー登録に成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(//現在の画面を破棄して別の画面に遷移できる
                        MaterialPageRoute(builder: (context) {
                          // ユーザー情報を渡す
                          return ChatPage();
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      setState(() {
                        infoText = "登録に失敗しました：${e.message}";
                      });
                    }
                  },
                ),
              ),
              Container(
                width: double.infinity,
                // ログイン登録ボタン
                child: OutlineButton(
                  textColor: Colors.blue,
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final AuthResult result =
                      await auth.signInWithEmailAndPassword(//ログインを行う
                        email: email,
                        password: password,
                      );
                      final FirebaseUser user = result.user;
                      // ユーザー情報を更新
                      userState.setUser(user);
                      // ログインに成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          // ユーザー情報を渡す
                          return ChatPage();//チャット画面へ
                        }),
                      );
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインに失敗しました：${e.message}";
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// チャット画面用Widget
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final FirebaseUser user = userState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),//✖︎アイコンクリックでログアウトにする
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているセッション情報が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();//ログアウト
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報：${user.email}'),
          ),
          Expanded(
            // StreamBuilder
            // 非同期処理の結果を元にWidgetを作れる
            //リアルタイム更新
            child: StreamBuilder<QuerySnapshot>(//クエリの結果が含まれる。コードの順序関係なく流れてきたデータをキャッチして処理を行う感じ
              // 投稿メッセージ一覧を取得（非同期処理）
              // 投稿日時でソート
              stream: Firestore.instance//表示したいFirestoreの保存先を指定
                  .collection('post')
                  .orderBy('date')
                  .snapshots(),//JSONのようなオブジェクトのプロパティへのアクセスと変換を簡素化
              builder: (context, snapshot) {//streamの引数によりstreamが更新されるたびに呼ばれる
                // データが取得できた場合
                //hasData = nul以外のデータが含まれているか
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents =//単一のドキュメントのデータを持つ
                      snapshot.data.documents;
                  // 取得した投稿メッセージ一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {//与えられた各要素に処理を掛けた後に、その要素群に対する新しいリストを作成する。
                      IconButton deleteIcon;
                      // 自分の投稿メッセージの場合は削除ボタンを表示
                      if (document['email'] == user.email) {//ドキュメントのEメールとユーザーEメール
                        //削除ボタン
                        deleteIcon = IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            // 投稿メッセージのドキュメントを削除
                            await Firestore.instance
                                .collection('post')
                                .document(document.documentID)
                                .delete();
                          },
                        );
                      }
                      return Card(
                        child: ListTile(
                          title: Text(document['text']),
                          subtitle: Text(document['email']),
                          trailing: deleteIcon,
                        ),
                      );
                    }).toList(),
                  );
                }
                // データが読込中の場合
                return Center(
                  child: Text('読込中...'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // 投稿画面に遷移
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              // 引数からユーザー情報を渡す
              return AddPostPage(user);
            }),
          );
        },
      ),
    );
  }
}

// 投稿画面用Widget
class AddPostPage extends StatefulWidget {
  // 引数からユーザー情報を受け取る
  AddPostPage(this.user);
  // ユーザー情報
  final FirebaseUser user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  // 入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    //ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final FirebaseUser user = userState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 投稿メッセージ入力
              TextFormField(
                decoration: InputDecoration(labelText: '投稿メッセージ'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    messageText = value;//入力された値
                  });
                },
              ),
              Container(
                width: double.infinity,
                child: RaisedButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text('投稿'),
                  onPressed: () async {
                    final date =
                    DateTime.now().toLocal().toIso8601String(); // 現在の日時
                    final email = user.email; // AddPostPage のデータを参照
                    // 投稿データ用ドキュメント作成
                    await Firestore.instance
                        .collection('post') // コレクションID指定
                        .document() // ドキュメントID自動生成
                        .setData({//データの追加
                      'text': messageText,
                      'email': email,
                      'date': date
                    });
                    // 1つ前の画面に戻る
                    Navigator.of(context).pop();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
