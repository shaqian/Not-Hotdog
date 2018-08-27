import React, {Component} from 'react';
import {
  Platform,
  StyleSheet
} from 'react-native';

import Svg,{
    Rect,
    G,
    Circle,
    Image,
    Text
} from 'react-native-svg';

import * as Animatable from 'react-native-animatable';

class Prediction extends Component {
  constructor(props) {
    super(props);
    this.state = {
      hotdog: props.hotdog,
      screen: props.screen,
    };
  }

  componentWillReceiveProps(nextProps) {
    const {hotdog, screen} = nextProps;
    this.setState({ hotdog, screen }); 
  }

  render() {
    const {hotdog, screen} = this.state;
    const width = screen.w;
    const height = 150;
    const rectHeight = height/2 - 10;
    return (
      <Animatable.View animation="slideInDown" style={styles.container}>
        <Svg
          height={height + 10}
          width={width}
        >
          <G fill="white" stroke="white" strokeWidth="4">
              <Circle cx={width/2} cy={height*2/3} r={height/3} />
              <Rect x="0" y="0" width={width} height={rectHeight} />
          </G>
          <G fill={hotdog? "lime": "red"}>
              <Circle cx={width/2} cy={height*2/3} r={height/3} />
              <Rect x="0" y="0" width={width} height={rectHeight} />
          </G>
          <Image
            x={(width - height/2)/2}
            y={Platform.OS === 'ios' ? 0 - 100 + height/4 : height/3 + height/12 }
            width={height/2}
            height={height/2}
            href={require('./images/hotdog.png')}
          />

          {!hotdog ?
            <G>
              <G x={width/2} y={height*2/3 - 2} fill="white" rotation="45" stroke="black" strokeWidth="2">
                <Rect x="0" y="-44" width="5" height="90" />
                <Rect x="-44" y="0" width="90" height="5" />
              </G>
              <G x={width/2} y={height*2/3 - 2} fill="white" rotation="45">
                <Rect x="0" y="-44" width="5" height="90" />
                <Rect x="-44" y="0" width="90" height="5" />
              </G> 
            </G>: undefined
          }
        </Svg>
        <Animatable.View style={styles.container} animation="rubberBand" delay={500}>
          <Svg
            height={rectHeight}
            width={width}
          >
            <Text
              fill="yellow"
              stroke="black"
              fontSize="40"
              fontWeight="bold"
              x={width/2}
              y={height/4 + 10}
              textAnchor="middle"
            >
              {hotdog? "Hotdog!": "Not hotdog!"}
            </Text> 
          </Svg>
        </Animatable.View>
      </Animatable.View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    backgroundColor: 'transparent',
  }
});

export default Prediction;
