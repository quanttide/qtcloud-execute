import "./App.css";

function App() {
  return (
    <div className="app">
      <header className="hero">
        <h1>执行云</h1>
        <p className="tagline">把执行变成系统能力</p>
        <p className="positioning">
          把人的能力系统性转译成系统的能力——让执行从「靠人记得」变成「靠系统看清」。
        </p>
      </header>

      <section className="pain">
        <h2>你有没有过这种感觉</h2>
        <p>
          任务多起来的时候，最累的不是做事，是心里一直悬着一件事：
          是不是漏了什么。哪个在做、哪个没开始、哪个卡住了——想不起来，只能靠回忆硬撑。
        </p>
        <p>
          做完的忘了记，没做完的也忘了。记住所有事，本身就是一件很耗心力的事。
          这份心力，本该留给做事本身。
        </p>
      </section>

      <section className="how">
        <h2>执行云帮你把执行变成系统的能力</h2>
        <div className="steps">
          <div className="step">
            <h3>看清</h3>
            <p>
              二维看板，状态泳道——要做什么、不做什么，一眼看清，
              不用再在脑子里一遍遍地数。
            </p>
          </div>
          <div className="step">
            <h3>推进</h3>
            <p>
              拖拽推进状态，即改即存——改一下就是推进，
              不用停下来整理记录，看板即时刷新。
            </p>
          </div>
          <div className="step">
            <h3>提炼</h3>
            <p>
              AI 从日志里提炼任务，人确认——你不记得的，系统替你记得。
              <span className="badge">规划中</span>
            </p>
          </div>
        </div>
      </section>

      <footer>
        <p>执行云 · execute.cloud.quanttide.com</p>
      </footer>
    </div>
  );
}

export default App;
